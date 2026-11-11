class Avo::Cards::StockReceived < Avo::Cards::ChartkickCard
  self.id = "stock_received"
  self.label = "Stock received"
  self.description = "Units that came in, week by week"
  self.chart_type = :column_chart
  self.cols = 2
  self.rows = 2
  self.flush = false
  self.scale = true

  def query
    weeks = (0..8).map { |ago| Date.current.beginning_of_week - ago.weeks }.reverse
    received = StockMovement.receipt.where(created_at: weeks.first.beginning_of_day..).pluck(:created_at, :quantity)
      .group_by { |at, _units| at.to_date.beginning_of_week }.transform_values { |rows| rows.sum(&:last) }

    result [{name: "Units", data: weeks.map { |week| [week.strftime("%b %-d"), received[week].to_i] }}]
  end
end
