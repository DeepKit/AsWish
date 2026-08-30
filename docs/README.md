# AsWish Docs

> Current engineering entry: `../README.md`, `../SPEC.md`, and `CTF.md`.
> Authoritative product identity: [`../ASWISH-PRODUCT-IDENTITY.md`](../ASWISH-PRODUCT-IDENTITY.md) · Documentation governance: [`../ASWISH-DOCUMENTATION-GOVERNANCE.md`](../ASWISH-DOCUMENTATION-GOVERNANCE.md).

## Authoritative Documents

| File | Role |
|---|---|
| `../README.md` | Public project entry |
| `../ASWISH-PRODUCT-IDENTITY.md` | Authoritative product identity (hierarchy, research questions, boundaries) |
| `../ASWISH-DOCUMENTATION-GOVERNANCE.md` | Documentation governance (authority registry, conflict rules) |
| `../SPEC.md` | Current v1.2-draft protocol and workflow baseline |
| `CTF.md` | Engineering explanation of the CTF method |
| `AsWish-用户上手说明-v1.md` | First-run, review, LLM, and CLI user path |
| `AsWish-当前文档索引-v1.md` | Chinese document index and historical map |
| `理论确权清单-v1.md` | Theory attribution, DOIs, claim strengths, pending items |

## Historical Documents

Many older documents mention "三棵树" because the early MVP model used function/module/view only. The current protocol target is four projections:

```text
function-tree / module-tree / view-tree / data-tree
```

When an old document conflicts with `../SPEC.md`, use `../SPEC.md` as the current engineering baseline. Do not delete old discussion files only because terminology changed; keep them as historical design context unless they leak secrets or are duplicated by a newer authoritative document.

Historical three-tree documents are marked inline and listed in the index; current user operations are maintained only in `AsWish-用户上手说明-v1.md`.

## Editing Rule

New public docs should describe AsWish first, then CTF, then ODD or other theory background only when necessary.
