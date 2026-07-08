# Achievements Specs & Contracts

This directory holds the complete locked contract for achievements, ensuring perfect product-to-engineering alignment, localization consistency, and backward-compatible local storage.

## 👁️ Current Status

- **v1 Specification**: [spec.md](./spec.md) (locked product & implementation contract)
- **Localization**: [strings.md](./strings.md) & [arb-key-plan.md](./arb-key-plan.md)
- **Data & Storage**: [db-schema-contract.md](./db-schema-contract.md)
- **Repository**: [repository-and-deeplink-contract.md](./repository-and-deeplink-contract.md)
- **Reminders**: [reminder-push-copy.md](./reminder-push-copy.md)
- **Art & Assets**: [art-key-convention.md](./art-key-convention.md)
- **Implementation Plan**: [implementation-chunks.md](./implementation-chunks.md)
- **Checklists**: [checklist-data-and-storage.md](./checklist-data-and-storage.md), [checklist-repository-and-sync.md](./checklist-repository-and-sync.md), [checklist-evaluator-engine.md](./checklist-evaluator-engine.md), [checklist-reminders-backend.md](./checklist-reminders-backend.md), [checklist-ui-and-navigation.md](./checklist-ui-and-navigation.md), [checklist-tests-and-rollout.md](./checklist-tests-and-rollout.md)

## 🗂️ Document Reference

- [spec.md](./spec.md): locked product and implementation contract
- [strings.md](./strings.md): exact v1 achievement names, labels, and descriptions
- [arb-key-plan.md](./arb-key-plan.md): localization key structure for achievements strings
- [db-schema-contract.md](./db-schema-contract.md): exact Supabase-side storage contract
- [repository-and-deeplink-contract.md](./repository-and-deeplink-contract.md): Dart repository API and route contract
- [reminder-push-copy.md](./reminder-push-copy.md): exact achievement reminder notification copy
- [art-key-convention.md](./art-key-convention.md): stable art-key and asset layout rules
- [implementation-chunks.md](./implementation-chunks.md): workable, testable implementation slices for handoff
- [checklist-data-and-storage.md](./checklist-data-and-storage.md): models, persistence, and schema work
- [checklist-repository-and-sync.md](./checklist-repository-and-sync.md): repository contract and local/Supabase behavior
- [checklist-evaluator-engine.md](./checklist-evaluator-engine.md): catalog, rules, and unlock evaluation
- [checklist-reminders-backend.md](./checklist-reminders-backend.md): hourly reminder evaluator and push delivery
- [checklist-ui-and-navigation.md](./checklist-ui-and-navigation.md): screens, routes, detail sheets, and celebration UX
- [checklist-tests-and-rollout.md](./checklist-tests-and-rollout.md): tests, QA, and rollout verification
