# frozen_string_literal: true

class Blog < ActiveRecord::Base
  validates :content, presence: true

  alias_attribute :headline, :title
  alias_attribute :text, :content

  def as_json(_options)
    {
      id: id,
      title: title,
      content: content,
      thumbnail: thumbnail
    }
  end
end
