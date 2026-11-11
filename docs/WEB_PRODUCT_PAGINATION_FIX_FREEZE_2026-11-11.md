# Web Product Pagination Fix Freeze — 2026-11-11

## Scope

- User App & Web only (`/Users/francisadediran/User app and web`).
- The store/restaurant **All Products** list on the store screen (mobile layout).
- Goal: stop the brief pause, which felt like a false "end of list", while scrolling and
  waiting for the next page.

## Root cause / behavior

What was established in code and tests:

- The All Products list is served by `GET /api/v1/items/latest` with a page size (`limit`) of
  **13**, and the API response reports that limit.
- `PaginatedListView` asked for the next page only when about **one screen** of loaded content
  was left. That is too close to the bottom, so a customer scrolling at a normal pace reached
  the end before the next page arrived.
- `PaginatedListView` computed the page count assuming **10** items per page, not the API's
  13. Near the end of a list this could ask for a page that doesn't exist (for example, 26
  products made it request an empty page 3).
- After a page finished loading, the widget called `setState` without checking it was still
  mounted. Leaving the store while a page was loading threw
  "setState() called after dispose".

The fix:

- Starts the next-page request earlier, while **3 screens** of content are still left
  (`preloadScreens: 3`).
- Derives the page count from the API limit.
- Keeps **one** in-flight page request at a time.
- Prevents duplicate page requests: each page number is requested once.
- Checks `mounted` after a page loads.

## Implementation

| File | Change |
|---|---|
| `lib/common/widgets/paginated_list_view.dart` | Two optional parameters, `limit` (API page size; null keeps the previous 10) and `preloadScreens` (default 1, the previous behaviour). Page count uses `limit`, for both the scroll trigger and the desktop "view more" condition. A `mounted` check after `onPaginate` completes. The existing one-in-flight and one-request-per-page guards are unchanged. |
| `lib/features/store/screens/store_screen.dart` | The mobile All Products `PaginatedListView` passes `limit: int.tryParse(storeController.storeItemModel?.limit ?? '')` (13 from the API response) and `preloadScreens: 3`. Two lines. |
| `test/store/store_product_pagination_test.dart` | Regression coverage: 8 new tests added beside the 7 existing ones. |

Every other `PaginatedListView` consumer passes neither parameter, so it keeps the previous
behaviour exactly (1 screen, 10 per page). Product ordering, the loading indicator, retry on the
next scroll after a failed page, and the product card design are unchanged.

## Validation

- Pagination tests (`test/store/store_product_pagination_test.dart`): **15/15 passed**,
  including the 8 new tests:
  - the request starts at a 3-screen threshold;
  - the default 1-screen behaviour is unchanged;
  - a page is never requested twice;
  - products stay in order and paging stops at the real last page;
  - an exact final page (26 products) makes no extra request;
  - a failed page shows the spinner, then retries on the next scroll;
  - reloading page 1 restarts paging;
  - leaving while a page is loading does not throw.
- Deliberate-break checks passed. Each old behaviour was restored temporarily (1-screen
  trigger, 10-per-page count, no `mounted` check) and the corresponding test failed. The files
  were restored and verified by checksum.
- Relevant regression suites (`test/{item,splash,checkout,home,store,favourite,location,moonjoin,profile,order,language,notification,api,auth,rental,common}`):
  **504/504 passed**.
- `flutter analyze` on the changed pagination files: **no issues**.

This is not a full-project test pass. Only the suites listed above were run.

## Separation / safety

- Web Performance Slice 2 (image-variant publishing, backend) is separate work.
- Web Performance Slice 3 (Flutter Web image-variant consumption) is already committed
  separately (`7388d70`).
- This pagination fix is intentionally kept separate from both.
- No backend API changes were made for this fix.
- No database or schema changes.
- No production deployment is part of this freeze.
- The existing release-record document
  (`docs/USER_APP_PAGINATION_PROCESSING_TIME_COUNTDOWN_FREEZE.md`) is not part of this change.

## Version

- Flutter 3.47.5
- Dart 3.13.4
- App version `1.0.26+37` (unchanged)
- `appVersion` 3.8 (unchanged)

## Git / release state at freeze time

- Branch `main`, HEAD `7388d7078212b16a3434dc73bc435b7a8f16543e` (the Slice 3 commit).
- The pagination commit has not been created yet. These changes are being prepared as a
  separate commit.
- No push, tag, build, archive or deployment has occurred for this pagination change.
