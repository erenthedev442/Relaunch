_legacy/ — retired deploy scripts (kept for reference, safe to delete)
=====================================================================

These were superseded and moved here on 2026-06-17 to de-clutter the
repo root. They are NOT used by any current button. Restore any of them
with:  git mv _legacy/<file> <original-path>

------------------------------------------------------------------
deploy-to-azure.bat        "Legendary - Deploy SQL to Live"
deploy-to-azure.config       (its saved-username file)
tools/_deploy_remote.sh      (its box-side helper; was orphaned)
------------------------------------------------------------------
WHY RETIRED: this pushed ONLY sql/zz_*.sql to live + restarted. That
job is now fully covered by:
  - deploy-no-rebuild.bat   (Lua + ALL SQL layers + restart, no C++)
  - deploy-everything.bat   (the above + C++ rebuild + website)
both of which apply every changed SQL file via tools/_apply_changed_sql.sh.

The Desktop shortcut "Legendary - Deploy SQL to Live" that pointed here
was also removed. Use the deploy-no-rebuild shortcut instead.

See DEPLOY-MAP.html in the repo root for the full current workflow.
