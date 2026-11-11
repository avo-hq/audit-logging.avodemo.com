# Lists longer than a page raise in Romanian and Norwegian Nynorsk on Avo 4.4.3 and older, whose own Pagy
# dictionaries for the two are out of date. The two languages come back by themselves with the next Avo release.
Rails.application.config.after_initialize do
  if Gem::Version.new(Avo::VERSION) < Gem::Version.new("4.4.4")
    I18n.available_locales = I18n.available_locales - [:ro, :nn]
  end
end
