# Design notes

## Changes from the original SQL export

- Added `Hire_Item` so one agreement can contain multiple physical items, each with its own expected and actual return date.
- Separated equipment types from physical equipment. `Equipment_Hire_Rate` stores Student, Staff/Alumni, and Guest rates per type; staff and alumni share one rate category.
- Replaced the global discount tariff with customer-category reference data.
- Added the trip code to registrations and used the complete scheduled-trip key. The original SQL already had a composite scheduled-trip primary key, a sponsor foreign key, and a staff-qualification primary key.
- Removed the accidental uniqueness constraint on insurance-waiver status. Multiple registrations can have the same boolean status.
- Used numeric fees, durations and vehicle capacities, text phone numbers, and matching foreign-key column types.
- Stored payments on receipts, and retained the daily rate agreed for each hire item as a historical snapshot.
- Included acquisition date in the staff-qualification key to retain renewal history.

## Assumptions

A vehicle is assigned to at most one trip per day. Members do not themselves have sponsors. A guest must have a sponsor and cannot sponsor themselves. Hire dates use day-level precision. Receipts record positive payments; refunds and charge calculations are outside this revision. Qualification validity is measured in months; zero represents no expiry.

## Rules still requiring implementation

- Verify that each guest's sponsor is a university member, including when a sponsor changes customer category.
- Prevent overlapping hires of the same physical equipment and enforce that return dates are on or after the hire date.
- Ensure every equipment type has all three rate categories, and select the correct category when recording an agreed hire rate.
- Ensure every hire agreement contains at least one item.
- Check required and valid staff qualifications before assigning leaders or drivers. The qualification tables store credentials; they do not by themselves enforce eligibility.
- Check vehicle capacity and conflicts across multi-day trips; the current key prevents only same-day duplicate assignments.

## Original documentation

The archived report describes the original schema and contains illustrative data that is not directly loadable into the revised design. Some report claims exceed what its schema enforces. The report is retained locally, not tracked, because it contains student identifiers.

The course brief asks for an extension of two to three tables. The original team report describes four extension tables covering vehicles and qualifications. This repository preserves that historical scope and does not claim to be a newly validated assignment submission.

## Validation

Static review checks primary keys and foreign-key target columns/types. Live MySQL execution, sample data, negative constraint tests, and a revised Workbench model remain future work.
