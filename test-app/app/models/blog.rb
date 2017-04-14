class Blog < ActiveRecord::Base
  validates :content, presence: true

  def as_json(options)
    {
      id: id,
      title: title,
      content: content,
      thumbnail: thumbnail
    }
  end
end
