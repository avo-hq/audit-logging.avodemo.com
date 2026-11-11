class Avo::Cards::ChangesFromOutside < Avo::Cards::ChartkickCard
  self.id = "changes_from_outside"
  self.label = "Changes from outside the panel"
  self.description = "The last 60 days, by where they came in"
  self.chart_type = :bar_chart
  self.rows = 2
  self.flush = false
  self.scale = true

  def query
    origins = Avo::AuditLogging::Activity.where.not(origin: nil).where(created_at: 60.days.ago..).group(:origin).count
    # "Background job (Restock low stock)" and its like count as their kind: the chart has room for the kind only.
    kinds = origins.each_with_object(Hash.new(0)) do |(origin, count), sums|
      sums[Avo::AuditLogging::Activity.new(origin: origin).origin_label.sub(/ \(.*\)\z/, "")] += count
    end
    largest, rest = kinds.sort_by { |_kind, count| -count }.partition.with_index { |_pair, at| at < 5 }

    # One series, so every bar wears one colour: the labels already say which is which.
    result [{name: "Changes", data: rest.any? ? [*largest, ["Other", rest.sum(&:last)]] : largest}]
  end
end
