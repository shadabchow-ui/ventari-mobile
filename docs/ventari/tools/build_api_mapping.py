#!/usr/bin/env python3
"""Build the Bagisto GraphQL -> Ventari contract mapping from the audited operation inventory.

    python3 docs/ventari/tools/build_api_mapping.py

Input: docs/ventari/audit/graphql_operations.csv (every GraphQL operation in lib/ at 18a2c27).
Output: docs/ventari/VENTARI_BAGISTO_TO_VENTARI_API_MAPPING.csv. Fails if any operation is unmapped.
Ventari endpoints: catalog BFF v2 = /api/ventari/v2/* (exists today in ventari-shopware);
mobile commerce BFF v1 = /api/ventari/m/v1/* (proposed: VJ-132 contract, VJ-170 implementation).
"""
import csv, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
V2, M1 = "/api/ventari/v2", "/api/ventari/m/v1"

# root GraphQL field -> (classification, Ventari replacement, owning job, notes)
BY_ROOT = {
    # catalog
    "product": ("REPLACE", f"GET {V2}/products/{{slug}}", "VJ-148", "ProductV2 envelope; variants carry priceCents/availability/sellable; redirect outcome for alias slugs"),
    "products": ("REPLACE", f"GET {V2}/search?category=&sort=&cursor=", "VJ-146", "cursor (Relay-like) pagination, ≤48 per page"),
    "treeCategories": ("REPLACE", f"GET {V2}/categories", "VJ-146", "canonical Cloudflare category tree"),
    "categories": ("REPLACE", f"GET {V2}/categories?parent=", "VJ-146", ""),
    "categoryAttributeFilters": ("REPLACE", f"GET {V2}/search (facets[])", "VJ-146", "facets come with each search page"),
    "attribute": ("REPLACE", f"GET {V2}/search (facets[])", "VJ-146", ""),
    "sections": ("ADAPT", f"GET {V2}/search + {V2}/categories (deterministic rails)", "VJ-146", "Bagisto CMS theme sections have no Ventari equivalent; home is composed from catalog rails (web VJ-078 pattern)"),
    "bookingSlots": ("REMOVE", "—", "VJ-148", "booking products are not a Ventari product type"),
    # cart
    "createCartToken": ("REPLACE", f"POST {M1}/session/guest", "VJ-170", "opaque Ventari session token; Shopware context token stays server-side"),
    "createAddProductInCart": ("REPLACE", f"POST {M1}/cart/items (Idempotency-Key)", "VJ-149", "server mints the signed offer; client sends slug, sku, quantity only"),
    "createReadCart": ("REPLACE", f"GET {M1}/cart", "VJ-149", "totals, notices (repriced, out of stock) from the server"),
    "createUpdateCartItem": ("REPLACE", f"PATCH {M1}/cart/items/{{lineId}} (Idempotency-Key)", "VJ-135", "atomic re-quote + re-reserve"),
    "createRemoveCartItem": ("REPLACE", f"DELETE {M1}/cart/items/{{lineId}}", "VJ-149", "releases reservation"),
    "createApplyCoupon": ("REPLACE", f"POST {M1}/cart/promotion", "VJ-149", "plugin /store-api/ventari/promotion"),
    "createRemoveCoupon": ("REPLACE", f"DELETE {M1}/cart/promotion/{{code}}", "VJ-149", ""),
    "createMergeCart": ("REPLACE", f"POST {M1}/session/login (merges guest cart)", "VJ-145", "VJ-057 merge semantics"),
    # checkout
    "collectionGetCheckoutAddresses": ("REPLACE", f"GET {M1}/account/addresses", "VJ-150", ""),
    "collectionShippingRates": ("REPLACE", f"GET {M1}/checkout/shipping-methods + {V2}/delivery-promise", "VJ-150", "rates from Shopware; promise from VJ-118"),
    "collectionPaymentMethods": ("REPLACE", f"GET {M1}/checkout/payment-methods", "VJ-151", "PSP sheet; no redirect gateways"),
    "createCheckoutAddress": ("REPLACE", f"PUT {M1}/checkout/address", "VJ-150", "US-only, validated server-side (AddressValidationSubscriber)"),
    "createCheckoutShippingMethod": ("REPLACE", f"PUT {M1}/checkout/shipping-method", "VJ-150", ""),
    "createCheckoutPaymentMethod": ("REPLACE", f"POST {M1}/checkout/payment-session", "VJ-152", "amount from the Shopware order, never from the client"),
    "createCheckoutOrder": ("REPLACE", f"POST {M1}/checkout/order (Idempotency-Key) + GET {M1}/orders/lookup?key=", "VJ-136", "retry returns the same order"),
    "countries": ("REPLACE", f"GET {M1}/checkout/countries (US only at launch)", "VJ-150", "OD-04"),
    "countryStates": ("REPLACE", f"GET {M1}/checkout/countries/US/states", "VJ-150", ""),
    # auth / account
    "createCustomerLogin": ("REPLACE", f"POST {M1}/session/login", "VJ-145", "token to Keychain/Keystore, not SharedPreferences"),
    "createCustomer": ("REPLACE", f"POST {M1}/account/register", "VJ-153", "double opt-in per VJ-082"),
    "createForgotPassword": ("REPLACE", f"POST {M1}/account/recovery", "VJ-153", "VJ-082 recovery flow"),
    "createLogout": ("REPLACE", f"POST {M1}/session/logout", "VJ-145", "server revocation + local wipe"),
    "readCustomerProfile": ("REPLACE", f"GET {M1}/account/profile", "VJ-153", ""),
    "createCustomerProfileUpdate": ("REPLACE", f"PATCH {M1}/account/profile", "VJ-153", ""),
    "createCustomerProfileDelete": ("REPLACE", f"POST {M1}/account/deletion-request", "VJ-137", "complete deletion incl. Ventari tables"),
    "getCustomerAddresses": ("REPLACE", f"GET {M1}/account/addresses", "VJ-153", ""),
    "createAddUpdateCustomerAddress": ("REPLACE", f"PUT {M1}/account/addresses/{{id}}", "VJ-153", ""),
    "createDeleteCustomerAddress": ("REPLACE", f"DELETE {M1}/account/addresses/{{id}}", "VJ-153", ""),
    # wishlist / compare / reviews
    "wishlists": ("REPLACE", f"GET {M1}/saved-items", "VJ-153", "plugin /store-api/ventari/saved-items (VJ-024)"),
    "createWishlist": ("REPLACE", f"POST {M1}/saved-items", "VJ-153", ""),
    "deleteWishlist": ("REPLACE", f"DELETE {M1}/saved-items/{{sku}}", "VJ-153", ""),
    "moveWishlistToCart": ("REPLACE", f"POST {M1}/cart/items (Idempotency-Key)", "VJ-149", "client composes save→cart; server re-quotes"),
    "compareItems": ("DEFER", "local state + {V2}/products (VJ-030 contract)", "VJ-169", "compare is v1.1"),
    "createCompareItem": ("DEFER", "local only", "VJ-169", ""),
    "deleteCompareItem": ("DEFER", "local only", "VJ-169", ""),
    "createDeleteAllCompareItems": ("DEFER", "local only", "VJ-169", ""),
    "productReviews": ("DEFER", "first-party reviews API (VJ-023/VJ-099)", "VJ-169", "never import review text without rights (OD-03)"),
    "customerReviews": ("DEFER", "first-party reviews API", "VJ-169", ""),
    "createProductReview": ("DEFER", "first-party reviews API", "VJ-169", ""),
    # orders
    "customerOrders": ("REPLACE", f"GET {M1}/orders?cursor=", "VJ-153", ""),
    "customerOrder": ("REPLACE", f"GET {M1}/orders/{{id}}", "VJ-153", "status timeline + tracking (VJ-032)"),
    "customerOrderShipments": ("REPLACE", f"GET {M1}/orders/{{id}} (deliveries[])", "VJ-153", ""),
    "customerOrderShipment": ("REPLACE", f"GET {M1}/orders/{{id}} (deliveries[])", "VJ-153", ""),
    "customerInvoices": ("REPLACE", f"GET {M1}/orders/{{id}}/documents", "VJ-153", "Shopware documents; merchant-of-record identity (VJ-076)"),
    "customerInvoice": ("REPLACE", f"GET {M1}/orders/{{id}}/documents/{{docId}}", "VJ-153", ""),
    "createCancelOrder": ("REPLACE", f"POST {M1}/orders/{{id}}/cancel (Idempotency-Key)", "VJ-175", "VJ-117 customer cancellation; server preview first"),
    "createReorderOrder": ("ADAPT", f"POST {M1}/cart/items per line (re-quoted)", "VJ-175", "never reuses old prices"),
    "customerDownloadableProducts": ("REMOVE", "—", "VJ-153", "no downloadable goods"),
    # returns
    "customerReturns": ("REPLACE", f"GET {M1}/returns", "VJ-175", "VJ-033 RMA"),
    "customerReturn": ("REPLACE", f"GET {M1}/returns/{{id}}", "VJ-175", ""),
    "returnableOrders": ("REPLACE", f"GET {M1}/returns/eligible-orders", "VJ-175", "30-day window per OD-09"),
    "returnableItems": ("REPLACE", f"GET {M1}/returns/eligible-orders/{{id}}/items", "VJ-175", ""),
    "returnReasons": ("REPLACE", f"GET {M1}/returns/reasons", "VJ-175", ""),
    "customerReturnMessages": ("DEFER", "support thread (VJ-034)", "VJ-175", ""),
    "createCustomerReturn": ("REPLACE", f"POST {M1}/returns (Idempotency-Key)", "VJ-175", "refund amount previewed by RefundService"),
    "cancelCustomerReturn": ("REPLACE", f"POST {M1}/returns/{{id}}/cancel", "VJ-175", ""),
    "reopenCustomerReturn": ("REMOVE", "—", "VJ-175", "merchant-side action in Ventari"),
    "closeCustomerReturn": ("REMOVE", "—", "VJ-175", "merchant-side action"),
    "createCustomerReturnMessage": ("DEFER", "support thread (VJ-034)", "VJ-175", ""),
    "euWithdrawalStatus": ("REMOVE", "—", "VJ-153", "EU withdrawal: US-only launch (OD-04)"),
    "euWithdrawals": ("REMOVE", "—", "VJ-153", ""),
    "createEuWithdrawal": ("REMOVE", "—", "VJ-153", ""),
    "createGuestEuWithdrawal": ("REMOVE", "—", "VJ-153", ""),
    # store / misc
    "storeConfig": ("REPLACE", f"GET {M1}/config", "VJ-160", "min version, kill switch, feature flags; no Bagisto admin theming"),
    "channel": ("REMOVE", "—", "VJ-144", "single Ventari channel"),
    "locales": ("REMOVE", "—", "VJ-144", "en-US at launch; l10n files kept for later markets"),
    "currencies": ("REMOVE", "—", "VJ-144", "USD only at launch"),
    "pages": ("ADAPT", "web help pages via in-app browser tab or BFF markdown (VJ-006)", "VJ-153", "owner-approved terms only"),
    "createContactUs": ("REPLACE", f"POST {M1}/support/contact", "VJ-153", "VJ-034 contact entry"),
}
FRAGMENT = ("REPLACE", "generated Dart models from OpenAPI (VJ-133)", "VJ-171", "fragments disappear with GraphQL")
SPECIAL = {  # operation names whose root field is ambiguous
    "productGuestCheckout": ("REMOVE", "—", "VJ-149", "guest checkout is a server policy; the client does not decide"),
    "customerSuspension": ("REMOVE", "—", "VJ-150", "account state enforced server-side"),
    "bookingCancellation": ("REMOVE", "—", "VJ-153", "no booking products"),
    "GetRelatedProducts": ("REPLACE", f"GET {V2}/similar?slug=", "VJ-148", "deterministic similar rail with truthful label (VJ-026)"),
}


def main():
    rows = list(csv.DictReader(open(ROOT / "audit/graphql_operations.csv")))
    out, missing = [], []
    for r in rows:
        name, root = r["operation_name"], r["top_level_fields"].split(";")[0].strip()
        if r["kind"] == "fragment":
            m = FRAGMENT
        elif name in SPECIAL:
            m = SPECIAL[name]
        elif name.startswith(("GetBooking",)) or "Booking" in name:
            m = ("REMOVE", "—", "VJ-148", "booking products are not a Ventari product type")
        elif "Downloadable" in name or "Grouped" in name or "Bundle" in name:
            m = ("REMOVE", "—", "VJ-149", "Ventari sells simple and variant external SKUs only")
        else:
            m = BY_ROOT.get(root)
        if not m:
            missing.append(f"{name} ({root})"); continue
        out.append({"bagisto_operation": name, "kind": r["kind"], "bagisto_root_field": root, "defining_file": r["defining_file"],
                    "feature": r["feature"], "classification": m[0], "ventari_replacement": m[1], "owning_job": m[2], "notes": m[3],
                    "used_by": r["used_by"]})
    if missing:
        sys.exit("UNMAPPED: " + ", ".join(missing))
    with open(ROOT / "VENTARI_BAGISTO_TO_VENTARI_API_MAPPING.csv", "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(out[0].keys()), lineterminator="\n"); w.writeheader(); w.writerows(out)
    from collections import Counter
    print(len(out), dict(Counter(o["classification"] for o in out)))


if __name__ == "__main__":
    main()
