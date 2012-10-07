require 'epub/publication/package'

module EPUB
  module Publication
    class Package
      def to_xml
        Nokogiri::XML::Builder.new {|xml|
          xml.package('version' => '3.0',
                      'unique-identifier' => unique_identifier.id,
                      'xmlns' => EPUB::NAMESPACES['opf']) do
            (EPUB::Publication::Package::CONTENT_MODELS - [:guide]).each do |model|
              __send__(model).to_xml_fragment xml
            end
          end
        }.to_xml
      end

      class Metadata
        def to_xml_fragment(xml)
          xml.metadata('xmlns:dc' => EPUB::NAMESPACES['dc']) {
            (DC_ELEMS - [:languages]).each do |elems|
              singular = elems[0..-2]
              __send__("dc_#{elems}").each do |elem|
                node = xml['dc'].__send__(singular, elem.content)
                [:id, :lang, :dir].each do |attr|
                  val = elem.__send__(attr)
                  node[attr] = val if val
                end
              end
            end
            languages.each do |language|
              xml.language language
            end

            metas.each do |meta|
              node = xml.meta(meta.content)
              [:property, :id, :scheme].each do |attr|
                val = meta.__send__(attr)
                node[attr] = val if val
              end
              node['refines'] = "##{meta.refines.id}" if meta.refines
            end

            links.each do |link|
              node = xml.link
              [:href, :id, :media_type].each do |attr|
                val = link.__send__(attr)
                node[attr.to_s.gsub('_', '-')] = val if val
              end
              node['rel'] = link.rel.join(' ') if link.rel
              node['refines'] = "##{link.refines.id}" if link.refines
            end
          }
        end
      end

      class Manifest
        def to_xml_fragment(xml)
          node = xml.manifest {
            items.each do |item|
              item_node = xml.item
              [:id, :href, :media_type, :media_overlay].each do |attr|
                val = item.__send__(attr)
                item_node[attr.to_s.gsub('_', '-')] = val if val
              end
              item_node['properties'] = item.properties.join(' ') unless item.properties.empty?
              item_node['fallback'] = item.fallback.id if item.fallback
            end
          }
          node['id'] = id if id
        end
      end

      class Spine
        def to_xml_fragment(xml)
          node = xml.spine {
            itemrefs.each do |itemref|
              itemref_node = xml.itemref
              [:idref, :id].each do |attr|
                val = itemref.__send__(attr)
                itemref_node[attr] = val if val
              end
              itemref_node['linear'] = 'no' unless itemref.linear?
              itemref_node['properties'] = itemref.properties.join(' ') unless itemref.properties.empty?
            end
          }
          [:id, :toc, :page_progression_direction].each do |attr|
            val = __send__(attr)
            node[attr.to_s.gsub('_', '-')] = val if val
          end
        end
      end

      class Bindings
        def to_xml_fragment(xml)
          xml.bindings {
            media_types.each do |media_type|
              media_type_node = xml.mediaType
              media_type_node['media_type'] = media_type.media_type if media_type.media_type
              media_type_node['handler'] = media_type.handler.id if media_type.handler && media_type.handler.id
            end
          }
        end
      end
    end
  end
end