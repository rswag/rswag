# frozen_string_literal: true

class Blog < ActiveRecord::Base
  validates :content, presence: true

  alias_attribute :headline, :title
  alias_attribute :text, :content

  # Rails 7.0 introduced new syntax to define enums.
  # See https://github.com/rails/rails/pull/50987
  if Gem::Version.new(Rails.version) >= Gem::Version.new('7.0')
    enum :status, { draft: 0, published: 1, archived: 2 }
  else
    enum status: { draft: 0, published: 1, archived: 2 }
  end

  def as_json(_options)
    {
      id: id,
      title: title,
      content: content,
      thumbnail: thumbnail
    }
  end
end
