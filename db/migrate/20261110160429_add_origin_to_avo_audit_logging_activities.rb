# Where an activity came from, when it did not come from somebody clicking in the panel.
#
# Added after the activities table shipped, so it is its own migration: an app that installed
# avo-audit_logging before this version runs `bin/rails generate avo:audit_logging install`
# again and gets exactly this file.
#
# `origin` is the short name of whatever acted — "mcp_server" for an AI client connected through
# avo-mcp_server — and NULL for the panel itself, which is what the overwhelming majority of rows
# are. `origin_record` points at the thing that acted where there is one to point at, so the entry
# can be read back to the connection that made it.
class AddOriginToAvoAuditLoggingActivities < ActiveRecord::Migration[7.2]
  def change
    # An app that squashed its migrations says nothing about these columns in any file, so the
    # installer cannot tell whether it already has them and writes this migration to be safe.
    # Asking the database is what settles it — and makes the migration a no-op rather than a
    # "column origin already exists" halfway through a deploy.
    return if column_exists?(:avo_audit_logging_activities, :origin)

    add_column :avo_audit_logging_activities, :origin, :string
    add_index :avo_audit_logging_activities, :origin

    add_reference :avo_audit_logging_activities, :origin_record,
      polymorphic: true,
      null: true,
      index: {name: "index_avo_audit_logging_activities_on_origin_record"}
  end
end
