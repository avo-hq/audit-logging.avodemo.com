class Avo::Cards::ChangesLogged < Avo::Cards::ChartkickCard
  self.id = "changes_logged"
  self.label = "Changes logged"
  self.description = "Creates, updates, deletes and action runs in the audit log, per day"
  self.chart_type = :area_chart
  self.cols = 2
  self.rows = 2
  self.initial_range = 30
  self.ranges = {"7 days": 7, "30 days": 30, "60 days": 60}

  def query
    days = range.to_i.days.ago.to_date..Date.current
    changes = Avo::AuditLogging::Activity.where.not(action: %w[index show new edit])
      .where(created_at: days.first.beginning_of_day..).group("date(created_at)").count

    # Every day gets a point: a day with no change is a zero, not a gap the line would bridge.
    result [{name: "Changes", data: days.map { |day| [day, changes[day.to_s].to_i] }}]
  end
end
