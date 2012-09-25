class CreateRefinerycmsPagesSchema < ActiveRecord::Migration
  def up
    create_table "#{Refinery::Core.config.table_prefix}page_parts" do |t|
      t.integer  "#{Refinery::Core.config.table_prefix}page_id"
      t.string   :title
      t.text     :body
      t.integer  :position

      t.timestamps
    end

    add_index "#{Refinery::Core.config.table_prefix}page_parts", :id
    add_index "#{Refinery::Core.config.table_prefix}page_parts", "#{Refinery::Core.config.table_prefix}page_id"

    create_table "#{Refinery::Core.config.table_prefix}pages" do |t|
      t.integer   :parent_id
      t.string    :path
      t.string    :slug
      t.boolean   :show_in_menu,        :default => true
      t.string    :link_url
      t.string    :menu_match
      t.boolean   :deletable,           :default => true
      t.boolean   :draft,               :default => false
      t.boolean   :skip_to_first_child, :default => false
      t.integer   :lft
      t.integer   :rgt
      t.integer   :depth
      t.string    :view_template
      t.string    :layout_template

      t.timestamps
    end

    add_index "#{Refinery::Core.config.table_prefix}pages", :depth
    add_index "#{Refinery::Core.config.table_prefix}pages", :id
    add_index "#{Refinery::Core.config.table_prefix}pages", :lft
    add_index "#{Refinery::Core.config.table_prefix}pages", :parent_id
    add_index "#{Refinery::Core.config.table_prefix}pages", :rgt

    Refinery::PagePart.create_translation_table!({
      :body => :text
    })

    Refinery::Page.create_translation_table!({
      :title => :string,
      :custom_slug => :string,
      :menu_title => :string,
      :slug => :string
    })
  end

  def down
    drop_table "#{Refinery::Core.config.table_prefix}page_parts"
    drop_table "#{Refinery::Core.config.table_prefix}pages"
    Refinery::PagePart.drop_translation_table!
    Refinery::Page.drop_translation_table!
  end
end
