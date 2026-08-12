-- ┌──────────────────────────────┐
-- │ yaml-language-server config  │
-- └──────────────────────────────┘
--
-- Configuration of the 'yamlls' language server (yaml-language-server).
-- Merged into the base config by `:h vim.lsp.enable()` / `:h vim.lsp.config()`.
--
-- Notes:
-- - `schemaStore.enable = true` lets the server pull schemas from
--   https://www.schemastore.org, which covers GitHub Actions workflows,
--   docker-compose, and many others out of the box.
-- - Dedicated servers ('gh_actions_ls', 'azure_pipelines_ls',
--   'docker_compose_language_service') still run alongside this for their
--   language-specific features; this just adds schema validation everywhere.
-- - `keyOrdering = false` stops the annoying "wrong order" diagnostics.
return {
  settings = {
    yaml = {
      schemaStore = {
        enable = true,
        url = 'https://www.schemastore.org/api/json/catalog.json',
      },
      validate = true,
      keyOrdering = false,
    },
    redhat = { telemetry = { enabled = false } },
  },
}
