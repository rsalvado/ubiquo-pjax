/**
 *  Tools used in cropresize
 *
 *  All code is namespaced to Ubiquo.Media.CropResize to aviod collisions
 **/
if((typeof Ubiquo) == "undefined"){ 
    var Ubiquo = {};
}
if((typeof Ubiquo.Media) == "undefined"){ 
    Ubiquo.Media = {};
}
Ubiquo.Media.CropResize = {
    TabbedContent: {
        /*
            Params:
                parent: element that contains the childs [REQUIRED]
                tab_selector: class name to identify the tabs/labels that will be clicked
                content_selector: class name that identifies the childs that will
                    be hiden or shown.
                tab_activation_statuses: classes pairs [inactive tab, active tab]
                tab_selector_attribute: attribute from the tab that contains
                    the selector to find the content it targets
                tab_activation_statuses: an array with the off and on classes that
                    must be added to it
                other_selectors: an array of selectors which must be links to tab contents
                tab_activation_callback: function to run after a tab is activated
                all_content_can_be_hidden: a boolean to allow that condition

            CAUTION: intialization of firts active must be done aside "by hand"
         */
        init: function( params ){
            //Default values
            var opt = $H({
                parent: null,
                tab_selector: ".tab",
                content_selector: ".content",
                tab_selector_attribute: "rel",
                tab_activation_statuses: [null,"active"], //First for off and second for active
                other_selectors: [],
                tab_activation_callback: null,
                all_content_can_be_hidden: false // Disables the Toggle behaviour on tabs
            }).merge( $H(params) ).toObject();
            var parent = opt.parent;

            //Keeping data needed after.
            var relational_data = {
                "tabs": {},
                "links": {}
            };

            var activate_tab = function(tab, ctx ){
                tab.addClassName( opt.tab_activation_statuses[1] );
                if( opt.tab_activation_statuses[0] ) tab.removeClassName( opt.tab_activation_statuses[0] );
                if( opt.tab_activation_callback )
                    opt.tab_activation_callback( tab, ctx );
            };

            var deactivate_tab = function(tab){
                if( opt.tab_activation_statuses[0] ) tab.addClassName( opt.tab_activation_statuses[0] );
                tab.removeClassName( opt.tab_activation_statuses[1] );
            };

            var hide_all = function(){
                parent.select( opt.content_selector ).invoke("hide");

                parent.select( opt.tab_selector ).each(function(e){
                    deactivate_tab( e );
                });
            };

            //Shows a content by selector
            var activate_content_for = function( tab_or_link ){
                var ctx = { 
                    activated_on: tab_or_link
                };

                var selector = tab_or_link.readAttribute( opt.tab_selector_attribute );

                //Detect current active
                var current_content = parent.select( opt.content_selector ).find(function(elem){
                    return elem.visible();
                });

                //Retrieve content element
                var content = parent.select( selector ).first();
                ctx["content"] = content;
                if( current_content && current_content.identify() == content.identify() ){
                    if( opt.all_content_can_be_hidden ){
                        // If content is already shown, we hide it in spite of showing
                        content.hide();
                        //Use relational_data to know the tab of the content
                        var tab_id = null;
                        var content_id = content.identify();
                        $H(relational_data["tabs"]).each(function(pair){
                            if( pair.value.content_id == content_id) tab_id = pair.key;
                        });
                        deactivate_tab( $(tab_id), ctx );
                    }
                }else{
                    hide_all();
                    
                    content.show();

                    //Tab swapping: search which tab has the same content selector O(n)
                    var tab_to_activate = parent.select(opt.tab_selector).find(function(e){
                        return e.readAttribute( opt.tab_selector_attribute ) == selector;
                    });
                    activate_tab( tab_to_activate, ctx );
                }
            };

            //Set observers
            parent.select( opt.tab_selector ).each(function(tab){
                relational_data["tabs"][tab.identify()] = {
                    selector: tab.readAttribute( opt.tab_selector_attribute ),
                    content_id:  parent.select( tab.readAttribute( opt.tab_selector_attribute ) ).first().identify()
                }
                tab.observe("click",function(e){
                    activate_content_for( tab );
                    e.stop();
                })
            });

            //Other selectors, not tabs, that activate the contents
            opt.other_selectors.each( function(selector){
                parent.select( selector ).each(function(link){
                    relational_data["links"][link.identify()] = {
                        selector: link.readAttribute( opt.tab_selector_attribute ),
                        content_id:  parent.select( link.readAttribute( opt.tab_selector_attribute ) ).first().identify()
                    };
                    link.observe("click",function(e){
                        activate_content_for( link );
                        e.stop();
                    });
                });
            });
        }
    }
};
