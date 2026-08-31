# AsWish Interaction Specification v0.1

> Status: **Draft for Architect Review**
>
> Covers Dual-Surface interaction and the 0–9 Decision Surface protocol.

---

## 1. Two parallel surfaces

AsWish uses:

```text
Conversation Surface
        ↕
Decision Surface
```

They are parallel interaction modes with different responsibilities.

---

## 2. Conversation Surface

Conversation is for:

```text
Exploration
Discussion
Divergence
Clarification
Reframing
Understanding
```

Properties:

```text
Open-ended
Non-committal
```

Conversation content is not automatically Canonical Spec.

---

## 3. Decision Surface

Decision is for:

```text
Constrained judgment
Accept
Reject
Clarify
```

It should present an Observable object and make the Human's decision explicit.

---

## 4. Human-controlled transition

Required:

```text
Conversation
↓
Human decides that a decision is needed
↓
Decision Surface
```

The AI may suggest that a decision can now be made, but it must not silently force the transition on its own judgment.

---

## 5. 0–9 mapping

| Key | Semantic | Meaning | Canonical mutation |
|---|---|---|---|
| 1–7 | Choice.Option | Current candidates | Only after domain decision |
| 8 | Choice.Regenerate | Regenerate candidates | No |
| 9 | Choice.Input | Human says it directly | No direct mutation |
| 0 | Choice.Back | Return | No |

Mouse and keyboard must be semantically equivalent.

---

## 6. Accept / Reject / Clarify

The interaction protocol must remain distinct from domain semantics.

Example:

```text
Choice.Option #2
↓
Human chooses candidate #2
↓
Domain Decision = Accept
```

The exact mapping depends on the business flow.

The digits themselves are not:

```text
Accept = 1
Reject = 2
Clarify = 3
```

That would confuse navigation protocol with judgment semantics.

---

## 7. 9: Human Override

9 must provide a genuine open-text path.

It must support:

```text
Rejecting all candidates
Changing part of a candidate
Combining candidates
Adding constraints
Introducing a new direction
Rejecting the frame
```

The Human's statement becomes a new source input.

---

## 8. Frame Rejection

The interaction should preserve the difference between:

```text
"I reject option 2"
```

and:

```text
"None of these options addresses what I actually want."
```

The second case rejects the AI's frame, not merely an option.

---

## 9. 8: Regeneration

Regeneration should preserve the original problem context.

It must not:

- mutate the Canonical Spec;
- create a Decision;
- imply correctness;
- silently discard the prior candidate set if doing so would destroy auditability.

Whether prior candidate sets need explicit persistence should be decided against existing artifact/provenance capabilities.

---

## 10. 0: Back

Back is navigation only.

It is not:

```text
Reject
Cancel
Delete
Undo
```

A Back action must not create a domain Decision.

---

## 11. Human / AI boundary in the UI

Human controls:

```text
Whether to decide
What to accept
What to reject
What needs clarification
What revision is required
```

AI supplies:

```text
Candidates
Explanations
Questions
Transformations
Comparisons
```

The UI must not visually imply:

```text
AI recommendation = correct answer
```

---

## 12. Semantic color tokens

Use:

```text
Choice.Option
Choice.Regenerate
Choice.Input
Choice.Back
```

Light and Dark themes may use different RGB values.

But:

```text
semantic token = stable
visual RGB = theme-dependent
```

Numbers + text remain mandatory.

Color must not be the sole semantic carrier.

---

## 13. Interaction acceptance

A Decision Surface is complete only when:

```text
Human knows what is being judged
↓
Human can inspect it
↓
Human can choose / reject / clarify
↓
Domain Decision is recorded
↓
Outcome is traceable
```
