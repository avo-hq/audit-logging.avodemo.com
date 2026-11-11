# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  first_name             :string
#  last_name              :string
#  roles                  :json
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
class User < ApplicationRecord
  has_paper_trail

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :products

  # The team the seed makes. By address, never "everyone but visitors": anyone can sign up for an account, and
  # a list the tour fills with the team's rows must not hold another person's.
  TEAM = %w[avo@cado.com maya@example.com tomas@example.com priya@example.com jonas@example.com]

  scope :team, -> { where(email: TEAM) }
  scope :admins, -> { }
  scope :non_admins, -> { }

  def name
    "#{first_name} #{last_name}"
  end

  # A demo visitor's own account, made from nothing but the name they typed. With one each, what the tour calls
  # "yours" is one visitor's alone, however many take it at once.
  def self.visitor(name)
    first, last = name.to_s.gsub(/[^\p{L}\p{M}' -]/, "").squish.first(30).split(" ", 2)
    first ||= "Visitor"
    address = "#{[first, last].join(" ").parameterize.presence || "visitor"}-#{SecureRandom.hex(3)}@visitor.example"

    # Kept out of the audit log: an arrival is the demo's plumbing, and its entry would show a password hash.
    Avo::AuditLogging.disabled do
      PaperTrail.request(enabled: false) do
        create!(first_name: first, last_name: last, email: address, password: SecureRandom.hex(16),
          roles: {admin: true, manager: false, writer: false})
      end
    end
  end

  def is_developer? = roles["developer"]
  def is_admin? = roles["admin"]
end
