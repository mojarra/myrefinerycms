module Refinery
  class PagePart < Refinery::Core::BaseModel
    self.table_name = "#{Refinery::Core.config.table_prefix}page_parts"

    attr_accessible :title, :content, :position, :body, "#{Refinery::Core.config.table_prefix}page_id"
    belongs_to :page, :foreign_key => "#{Refinery::Core.config.table_prefix}page_id"

    validates :title, :presence => true
    alias_attribute :content, :body

    translates :body if respond_to?(:translates)

    def to_param
      "page_part_#{title.downcase.gsub(/\W/, '_')}"
    end

    def body=(value)
      super

      normalise_text_fields
    end

    self.translation_class.send :attr_accessible, :locale if self.respond_to?(:translation_class)

  protected
    def normalise_text_fields
      if body.present? && body !~ %r{^<}
        self.body = "<p>#{body.gsub("\r\n\r\n", "</p><p>").gsub("\r\n", "<br/>")}</p>"
      end
    end

  end
end
