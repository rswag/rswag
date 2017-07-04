migration_class = if Gem::Version.new(Rails.version) >= Gem::Version.new("5.0")
                    ActiveRecord::Migration[4.2]
                  else
                    ActiveRecord::Migration
                  end

class CreateBlogs < migration_class
  def change
    create_table :blogs do |t|
      t.string :title
      t.text :content
      t.string :thumbnail

      t.timestamps
    end
  end
end
