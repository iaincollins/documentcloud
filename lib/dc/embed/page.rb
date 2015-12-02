module DC
  module Embed
    class Page < Base
      class Config < Base::Config
        define_attributes do
          string  :container
          number  :maxheight
          number  :maxwidth
        end
      end

      def initialize(resource, embed_config={}, options={})
        # resource should be a wrapper object around a model 
        # which plucks out relevant metadata
        # Consider ActiveModel::Serializers for this purpose.
        # N.B. we should be able to generate oembed codes for things that are 
        # basically mocks of a document, not just for real documents
        [:id, :js_url].each do |attribute| 
          raise ArgumentError, "Embed resource must `respond_to?` an ':#{attribute}' attribute" unless resource.respond_to?(attribute)
        end
        @resource      = resource
        @embed_config  = Config.new(embed_config)
        @strategy      = options[:strategy]      || :literal # :oembed is the other option.
        @dom_mechanism = options[:dom_mechanism] || :direct

        @template_path = options[:template_path] || "#{Rails.root}/app/views/pages/_embed_code.html.erb"
        @template      = options[:template]
      end

      def template
        unless @template
          @template = ERB.new(File.read(@template_path))
          #@template.location = @template_path # uncomment this once deployed onto Ruby 2.2
        end
        @template
      end

      def render(data, options)
        template.result(binding)
      end

      # Change this
      def content_markup
        template_options = {
          :use_default_container => @embed_config[:container].nil? || @embed_config[:container].empty?,
          :default_container_id  => "DC-note-#{@resource.id}",
          :resource_js_url       => @resource.js_url
        }
    
        @embed_config[:container] ||= '#' + template_options[:default_container_id]
        render(@embed_config.dump, template_options)
      end

      def bootstrap_markup
        @strategy == :oembed ? inline_loader : static_loader
      end
  
      def inline_loader
        asset_root = DC.cdn_root(:agnostic => true)
        <<-SCRIPT
        <script>
          (function(){
            var ENV = window.ENV = window.ENV || {};
            ENV.config           = ENV.config || {};
            ENV.config.embed     = ENV.config.embed || { doc: {}, page: {}, note: {}, search: {} };
            ENV.config.embed.page.assetPaths = {
              style: "#{asset_root}/embed/page/page_embed.css",
              app:   "#{asset_root}/embed/page/page_embed.js"
            };
          })();

          if(!window.console){window.console={log:function(message){},info:function(message){},warn:function(message){},error:function(message){},};}
          (function(){var Penny=window.Penny=window.Penny||{VERSION:'0.0.0',on:function(el,eventName,handler){if(el.addEventListener){el.addEventListener(eventName,handler);}else{el.attachEvent('on'+eventName,function(){handler.call(el);});}},ready:function(fn){if(document.readyState!='loading'){fn();}else if(document.addEventListener){document.addEventListener('DOMContentLoaded',fn);}else{document.attachEvent('onreadystatechange',function(){if(document.readyState!='loading'){fn();}});}},each:function(collection,fn){if(collection!=null&&typeof collection==='object'){for(var key in collection){if(Penny.has(collection,key)){fn(collection[key],key);}}}else{var len=collection.length;for(i=0;i<len;i++){fn(collection[i],i);}}},has:function(obj,key){return obj!=null&&Object.prototype.hasOwnProperty.call(obj,key);},values:function(obj){var values=[];for(var key in obj){if(Penny.has(obj,key)){values.push(obj[key]);}}
          return values;},keys:function(obj){var keys=[];for(var key in obj){if(Penny.has(obj,key)){keys.push(obj[key]);}}
          return keys;},findKey:function(obj,fn){for(var key in obj){if(Penny.has(obj,key)){if(fn(obj[key],key)){return key;}}}
          return null;},extend:function(out){out=out||{};for(var i=1;i<arguments.length;i++){if(!arguments[i]){continue;}
          for(var key in arguments[i]){if(arguments[i].hasOwnProperty(key)){out[key]=arguments[i][key];}}}
          return out;},isString:function(thing){return!!(typeof thing==='string');},isElement:function(thing){return!!(thing&&thing.nodeType===1);},isEmpty:function(obj){if(obj==null){return true;}
          if(obj.length>0){return false;}
          if(obj.length===0){return true;}
          for(var key in obj){if(Penny.has(obj,key)){return false;}}
          return true;},};}());(function(){var DocumentCloud=window.DocumentCloud;var Penny=window.Penny;if(DocumentCloud&&DocumentCloud._){var _=DocumentCloud._;}else if(Penny){var _=Penny;}else{console.error("DocumentCloud embed can't load because of missing components.");return false;}
          var DCEmbedToolbelt=window.DCEmbedToolbelt=window.DCEmbedToolbelt||{isResource:function(thing){return!!(_.has(thing,'resourceType'));},recognizeResource:function(originalResource){if(this.isResource(originalResource)){return originalResource;}
          var domainEnvPatterns={production:'www\.documentcloud\.org',staging:'staging\.documentcloud\.org',development:'dev\.dcloud\.org'};var domains=_.values(domainEnvPatterns).join('|');var docBase='('+domains+')\/documents\/([0-9]+)-([a-z0-9-]+)';var resourceTypePatterns={'document':[docBase+'\.(?:html|js|json)$'],page:[docBase+'\.html#document\/p([0-9]+)$',docBase+'\/pages\/([0-9]+)\.(?:html|js|json)$'],note:[docBase+'\/annotations\/([0-9]+)\.(?:html|js|json)$',docBase+'\.html#document\/p[0-9]+\/a([0-9]+)$',docBase+'\.html#annotation\/a([0-9]+)$']};var makeDataUrl=function(resource){var urlComponents;switch(resource.resourceType){case'document':urlComponents=[resource.domain,'documents',resource.documentSlug];break;case'page':urlComponents=[resource.domain,'documents',resource.documentSlug];break;case'note':urlComponents=[resource.domain,'documents',resource.documentSlug,'annotations',resource.noteId];break;}
          return'//'+urlComponents.join('/')+'.json';};var resource={};_.each(resourceTypePatterns,function(patterns,resourceType){if(!_.isEmpty(resource)){return;}
          _.each(patterns,function(pattern){if(!_.isEmpty(resource)){return;}
          var match=originalResource.match(pattern);if(match){resource={resourceUrl:originalResource,resourceType:resourceType,environment:_.findKey(domainEnvPatterns,function(domain,env){return originalResource.match(domain);}),domain:match[1],documentId:match[2],documentSlug:match[2]+'-'+match[3],};switch(resourceType){case'document':resource.trackingId=resource.documentId;break;case'page':resource.pageNumber=match[4];resource.trackingId=resource.documentId+'p'+resource.pageNumber;resource.embedOptions={page:resource.pageNumber};break;case'note':resource.trackingId=resource.noteId=match[4];break;}
          resource.dataUrl=makeDataUrl(resource);}});});return resource;},ensureElement:function(thing){if(_.isElement(thing)){return thing;}else if(_.isString(thing)){return document.querySelector(thing);}else if(thing instanceof jQuery&&_.isElement(thing[0])){return thing[0];}
          return null;},generateUniqueElementId:function(resource){var i=1;var id='DC-'+resource.documentSlug;switch(resource.resourceType){case'document':id+='-i'+i;break;case'page':id+='-p'+resource.pageNumber+'-i'+i;break;case'note':id+='-a'+resource.noteId+'-i'+i;break;}
          while(document.getElementById(id)){id=id.replace(/-i[0-9]+$/,'-i'+i++);}
          return id;},isIframed:function(){try{return window.self!==window.top;}catch(e){return true;}},getSourceUrl:function(){var source,sourceUrl;if(this.isIframed()){source=document.createElement('A');source.href=document.referrer;}else{source=window.location;}
          sourceUrl=source.protocol+'//'+source.host;if(source.pathname.indexOf('/')!==0){sourceUrl+='/';};sourceUrl+=source.pathname;sourceUrl=sourceUrl.replace(/[\/]+$/,'');return sourceUrl;},pixelPing:function(resource,container){resource=this.recognizeResource(resource);container=this.ensureElement(container);var pingUrl='//'+resource.domain+'/pixel.gif';var sourceUrl=this.getSourceUrl();var key=encodeURIComponent(resource.resourceType+':'+resource.trackingId+':'+sourceUrl);var image='<img src="'+pingUrl+'?key='+key+'" width="1" height="1" class="DC-embed-pixel-ping" alt="Anonymous hit counter for DocumentCloud">';container.insertAdjacentHTML('afterend',image);}};})();(function(){Penny.ready(function(){if(!window.DCEmbedToolbelt){console.error("DocumentCloud embed can't load because of missing components.");return;}
          var insertStylesheet=function(href){if(!document.querySelector('link[href$="'+href+'"]')){var stylesheet=document.createElement('link');stylesheet.rel='stylesheet';stylesheet.type='text/css';stylesheet.media='screen';stylesheet.href=href;document.querySelector('head').appendChild(stylesheet);}};var insertJavaScript=function(src,onLoadCallback){if(!document.querySelector('script[src$="'+src+'"]')){var script=document.createElement('script');script.src=src;Penny.on(script,'load',onLoadCallback);document.querySelector('body').appendChild(script);}};var extractOptionsFromStub=function(stub){var options=stub.getAttribute('data-options');if(options){try{options=JSON.parse(options);}
          catch(err){console.error("Inline DocumentCloud embed options must be valid JSON. See https://www.documentcloud.org/help/publishing.");options={};}}else{options={};}
          return options;};var enhanceStubs=function(){var DocumentCloud=window.DocumentCloud;var stubs=document.querySelectorAll('.DC-embed');Penny.each(stubs,function(stub,i){if(stub.className.indexOf('DC-embed-enhanced')!=-1){return;}
          var resourceElement=stub.querySelector('.DC-embed-resource');var resourceUrl=resourceElement.getAttribute('href');var resource=DCEmbedToolbelt.recognizeResource(resourceUrl);if(!Penny.isEmpty(resource)){stub.className+=' DC-embed-enhanced';stub.setAttribute('data-resource-type',resource.resourceType);var embedOptions=Penny.extend({},extractOptionsFromStub(stub),resource.embedOptions,{container:stub});DocumentCloud.embed.load(resource,embedOptions);}else{console.error("The DocumentCloud URL you're trying to embed doesn't look right. Please generate a new embed code.");}});};var loadConfig=function(){var defaultConfig={page:{assetPaths:{app:"../dist/page_embed.js",style:"../dist/page_embed.css"}}};try{var envConfig=window.ENV.config.embed;}
          catch(e){var envConfig={};}
          return Penny.extend({},defaultConfig,envConfig);};var config=loadConfig();insertStylesheet(config.page.assetPaths.style);if(window.DocumentCloud){enhanceStubs();}else{insertJavaScript(config.page.assetPaths.app,enhanceStubs);}});})();
        </script>
        SCRIPT
      end
  
      def static_loader
        %(<script type="text/javascript" src="#{DC.cdn_root(:agnostic => true)}/embed/loader/enhance.js"></script>)
      end

      # intended for use in the static deployment to s3.
      def self.static_loader(options={})
        template_path = "#{Rails.root}/app/views/embed/enhance.js.erb"
        ERB.new(File.read(template_path)).result(binding)
      end
  
      def as_json
        if @strategy == :oembed
          {
            :type             => "rich",
            :version          => "1.0",
            :provider_name    => "DocumentCloud",
            :provider_url     => DC.server_root(:force_ssl => true),
            :cache_age        => 300,
            :height           => @embed_config[:maxheight],
            :width            => @embed_config[:maxwidth],
            :html             => code,
          }
        else
          @resource.as_json.merge(:html => code)
        end
      end
    end
  end
end