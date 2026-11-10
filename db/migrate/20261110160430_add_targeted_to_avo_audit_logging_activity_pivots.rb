# Which of an activity's records it was about: the one a person edited, or the ones an action ran on. The rest are
# records its save changed on the way, such as a callback's, and the activity's page lists those apart.
#
# Added after the activities table shipped, so it is its own migration: an app that installed avo-audit_logging
# before this version runs `bin/rails generate avo:audit_logging upgrade` and gets exactly this file.
class AddTargetedToAvoAuditLoggingActivityPivots < ActiveRecord::Migration[7.2]
  def change
    # An app that squashed its migrations tells the installer nothing, so the database settles it.
    return if column_exists?(:avo_audit_logging_activity_pivots, :targeted)

    add_column :avo_audit_logging_activity_pivots, :targeted, :boolean, default: false, null: false
  end
end
