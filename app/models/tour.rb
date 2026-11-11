require "digest"

# The guided tour's copy from config/tour.yml, and the recorded clip of each line Avo can say out loud.
class Tour
  # ElevenLabs' voice "Will" and its latest model. Both are part of a clip's name, so changing either records anew.
  VOICE = ENV.fetch("TOUR_VOICE", "bIHbv24MWmeRgasZH58o")
  MODEL = "eleven_v4"
  CLIPS = Rails.public_path.join("tour")

  # Named after what is said and in which voice, so an edited line has no clip until the task records it.
  def self.clip(spoken) = CLIPS.join("#{Digest::SHA1.hexdigest([VOICE, MODEL, spoken].join("|")).first(12)}.mp3")

  def initialize
    @copy = Rails.application.config_for(:tour)
  end

  # What the page gets: every line, with its clip's address in place of the performed text.
  def copy = @copy.merge(paused: for_browser(@copy[:paused]), steps: @copy[:steps].map { |step| for_browser(step) })

  # Every line as he performs it, emotion tags and all: what the task records.
  def spoken = [@copy[:paused], *@copy[:steps]].filter_map { |line| line[:voice] }

  private

  # The performed text stays on the server. The browser gets the clip's address, when the clip is recorded.
  def for_browser(line)
    clip = line[:voice] && self.class.clip(line[:voice])
    line.except(:voice).merge(clip: ("/tour/#{clip.basename}" if clip&.exist?)).compact
  end
end
