# PRD: Reorder Three

## Summary

A weekly email naming three products to reorder, built from the shop's existing sales export. For Priya. Twenty paying shops with fewer than five stock-outs a month by the end of 2026.

## Problem

Shop owners reorder from memory because their till reports data and recommends nothing. The brief's chain reaches a root cause: the tool reports, it does not recommend.

## User

Priya, 44, one gift shop, exports a CSV every Monday.

## Success metric and leading indicator

Twenty paying shops by 2026-12-31 with fewer than five stock-outs a month each. Leading indicator: ten shops forward the first email to a supplier.

## Scope

Decision: the smaller version. One CSV format, one email a week, three items. It leaves out multi-store and supplier integration. It would still move the number.

## Non-goals

- No dashboard.
- No inventory counting hardware.

## Requirements

1. The owner uploads a Square sales CSV and receives an email within ten minutes. Acceptance: a fixture CSV produces an email in under ten minutes in three of three trials.
2. The email names exactly three products with the reason for each. Acceptance: every email in a fixture month has three items and three one-sentence reasons. [C1]
3. The recommendation beats reorder-from-memory. Acceptance: on the fixture month, the three items include the top two by lost sales. [C2]

## Sequencing and dependencies

CSV parser before the model; the model before the email; the email before billing.

## Assumptions

- Square's CSV format is stable across the year. [C3]
- The premortem is pending.

## Risks

- Owners distrust a recommendation without a number. Mitigation: each reason carries the units sold last month.

## Open questions

- Square first, or Shopify.

## Appendix A. Challenged claims

| Claim | Challenged by | Severity | Status | Resolution |
|---|---|---|---|---|
| [C1] | unchallenged | | | |
| [C2] | unchallenged | | | |
| [C3] | unchallenged | | | |

## Appendix B. Premortem

Pending: written after the panel.
