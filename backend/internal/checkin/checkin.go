// Package checkin manages check-in capture across three privacy layers:
// Memory (shareable), Logistics (PRIVATE — never serialize to public/AI endpoints),
// and Recommendations (community-facing).
//
// Privacy enforcement: the Logistics layer must never be included in AI call payloads,
// published trip views, or any public-facing DTO. When Phase 2 is implemented, each
// layer should live in its own DTO type and ideally its own sub-package so the
// compiler can help enforce the boundary.
//
// Phase 2+.
package checkin
