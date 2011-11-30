module UbiquoAccessControl
  module Extensions
    module Helper

      # Add a link to the roles section
      def roles_link(navigator)
        navigator.add_link do |link|
          link.text = I18n.t("ubiquo.auth.roles")
          link.highlights << {:controller => "ubiquo/roles"}
          link.url = ubiquo_roles_path
        end if ubiquo_config_call(:role_permit, {:context => :ubiquo_access_control})
      end

      # Add a set of checkboxes to select/unselect roles
      def user_permission_fields(form)
        ubiquo_user_roles = form.object.ubiquo_user_roles.map(&:role)
        check_boxes = @roles.map do |role|
          content_tag("div", :class => "form-item") do
            label_tag("role"+role.id.to_s, role.name) + ' ' +
              check_box_tag("ubiquo_user[role_ids][]", role.id, ubiquo_user_roles.include?(role), {:class => "checkbox", :id => "role"+role.id.to_s})
          end
        end
        content_tag("fieldset") do
          content_tag("legend", t("ubiquo.auth.roles")) + check_boxes.join("\n")
        end + hidden_field_tag("ubiquo_user[role_ids][]", '')
      end

    end
  end
end
