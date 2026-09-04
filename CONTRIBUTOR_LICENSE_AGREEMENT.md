# Endurain Contributor License Agreement

Version 1.0, effective 2026-09-04

This Contributor License Agreement ("Agreement") applies to every Contribution submitted to the Endurain mobile app repository at `endurain-project/endurain-flutter` on or after the effective date.

## 1. Definitions

- **"Project Owner"** means João Vitória Silva, the current copyright and trademark owner of Endurain, and any person or legal entity that succeeds to ownership of the Endurain project or receives this Agreement by assignment.
- **"Contribution"** means any original work of authorship, including code, documentation, designs, tests, translations, or other material that You submit to the repository through a pull request, issue, discussion, or other project communication for inclusion in the project. It excludes material that You explicitly identify in writing as not a Contribution before submission and that the Project Owner agrees in writing to exclude.
- **"You"** means the individual submitting a Contribution. If You submit on behalf of an employer or other organization, You represent that You have authority to bind that organization, and "You" includes that organization.

## 2. Copyright License

You grant the Project Owner a perpetual, worldwide, non-exclusive, irrevocable, royalty-free, fully paid-up, transferable, and sublicensable license to use, reproduce, modify, prepare derivative works of, publicly display, publicly perform, distribute, make, have made, sell, offer for sale, import, and otherwise exploit Your Contribution and derivative works of it in any medium and under any license terms. This includes relicensing or sublicensing the Contribution, alone or as part of the project, under open source, source-available, proprietary, dual-license, commercial, or future license terms.

This license does not transfer ownership of Your Contribution. You retain copyright in it, subject to the rights granted by this Agreement. The Project Owner may, but is not required to, identify You as its author.

## 3. Patent License

To the extent that You have patent rights that would be infringed by Your Contribution or its use as part of the project, You grant the Project Owner and recipients of software distributed by the Project Owner a perpetual, worldwide, non-exclusive, irrevocable, royalty-free, transferable, and sublicensable patent license to make, have made, use, offer to sell, sell, import, and otherwise transfer the Contribution and derivative works of it.

## 4. Your Representations

You represent that:

1. You are legally entitled to grant the rights in this Agreement.
2. Your Contribution is Your original work, or You have all permissions  necessary to submit it and grant these rights.
3. Submitting the Contribution and granting these rights does not violate any  agreement, employment obligation, or third-party right.
4. You have disclosed in the pull request any material included under a  third-party license and have not knowingly included material that creates  undisclosed licensing obligations for the Project Owner.

To the extent permitted by applicable law, You waive and agree not to assert any moral rights in the Contribution against the Project Owner or its sublicensees when exercising the rights granted by this Agreement.

## 5. Acceptance

You accept this Agreement for a Contribution by checking the Contributor License Agreement box in that Contribution's pull request and submitting or updating the pull request through your GitHub account. That action is your electronic signature and records your acceptance for the identified Contribution. Do not submit the pull request if You do not agree or lack the authority to agree.

## 6. Other Licenses

The repository is currently offered under the GNU Affero General Public
License v3.0. This Agreement grants additional rights to the Project Owner; it
does not withdraw rights already granted to the public under that license.

## 7. No Obligation

The Project Owner is not required to accept, merge, use, or distribute any Contribution. This Agreement does not create an employment, agency, partnership, or joint-venture relationship.

## 8. Governing Law

This Agreement is governed by the laws of Portugal, excluding its conflict of laws rules. The courts with jurisdiction over the Project Owner's principal residence have exclusive jurisdiction over disputes arising from this Agreement, except where mandatory law requires otherwise.

## 9. Entire Agreement and Severability

This Agreement is the entire agreement concerning its subject matter. If a provision is unenforceable, the remaining provisions remain effective and the unenforceable provision will be interpreted as closely as permitted by law to give effect to its purpose.

This is a contributor agreement with legal consequences. Contributors and the Project Owner should obtain independent legal advice for questions about its effect, employment obligations, or jurisdiction.

## Maintainer Setup

The repository workflow validates the pull request attestation, but GitHub must also be configured to make that validation a merge gate. Before accepting external contributions, create a branch ruleset for `main` in GitHub under **Settings > Rules > Rulesets** that requires the status check:

`Contributor License Agreement / Verify contributor agreement`

Apply the ruleset to administrators and maintainers who can merge pull requests, and do not allow bypasses for this check. Requiring the branch to be up to date before merging ensures that the check is evaluated against the current base branch. Keep an export or record of accepted pull requests and their bodies as evidence of each contributor's electronic acceptance.