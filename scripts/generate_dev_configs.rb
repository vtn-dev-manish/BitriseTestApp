#!/usr/bin/env ruby
require "fileutils"
require "json"

SECRETS_CACHE_FILE = File.expand_path("~/.ua_secrets")
BRANDS = %w(barcoo ofertolino marktjagd offeristafr profital wogibtswas wunderkauf)
BUILDS = %w(debug beta release)
TEMPLATE = <<XML
<?xml version='1.0' encoding='utf-8'?>
<resources>
%s
</resources>
XML
CONFIGS = {
  "api_base_uri" => {
    type: "string",
    max_level: :build,
    "debug" => {
      default: "https://delivery-public-elb.ws-stage.offerista.com/"
    },
    "beta" => {
      default: "https://delivery.offerista.com/"
    },
    "release" => {
      default: "https://delivery.offerista.com/"
    }
  },
  "api_key" => {
    type: "string",
    max_level: :brand_build
  },
  "api_secret" => {
    type: "string",
    max_level: :brand_build
  },
  "og_trackings_endpoint" => {
    type: "string",
    max_level: :build,
    default: "https://tracking.offerista.com/trackings",
    "debug" => {
      default: "https://tracking-receiver-elb.ws-stage.offerista.com/trackings"
    }
  },
  "portal_host" => {
    type: "string",
    required: true,
    max_level: :brand,
    "barcooDebug" => {
      default: "barcoo-de.portal-elb.frontend-stage.offerista.com"
    },
    "barcoo" => {
      default: "barcoo.de"
    },
    "ofertolinoDebug" => {
      default: "marktjagd-de.legacy-portal-elb.frontend-stage.offerista.com"
    },
    "ofertolino" => {
      default: "marktjagd.de"
    },
    "marktjagdDebug" => {
      default: "marktjagd-de.legacy-portal-elb.frontend-stage.offerista.com"
    },
    "marktjagd" => {
      default: "marktjagd.de"
    },
    "offeristafrDebug" => {
      default: "offerista-fr.portal-elb.frontend-stage.offerista.com"
    },
    "offeristafr" => {
      default: "offerista.fr"
    },
    "profitalDebug" => {
      default: "profital-ch.legacy-portal-elb.frontend-stage.offerista.com"
    },
    "profital" => {
      default: "profital.ch"
    },
    "wogibtswasDebug" => {
      default: "wogibtswas-at.portal-elb.frontend-stage.offerista.com"
    },
    "wogibtswas" => {
      default: "wogibtswas.at"
    },
    "wunderkaufDebug" => {
      default: "barcoo-de.portal-elb.frontend-stage.offerista.com"
    },
    "wunderkauf" => {
      default: "barcoo.de"
    }
  },
  "asset_statements" => {
    type: "string",
    max_level: :brand,
    default: "[{\\'include\\': \\'https://%%portal_host%%/.well-known/assetlinks.json\\'}]",
  },
  "api_portal_base_uri" => {
    type: "string",
    default: "https://%%portal_host%%/api/",
    max_level: :brand,
    "barcooDebug"  => {
      default: "https://marktjagd-de.legacy-portal-elb.frontend-stage.offerista.com/api/"
    },
    "barcoo" => {
      default: "https://marktjagd.de/api/"
    },
    "wunderkaufDebug" => {
      default: "https://marktjagd-de.legacy-portal-elb.frontend-stage.offerista.com/api/"
    },
    "wunderkauf" => {
      default: "https://marktjagd.de/api/"
    }
  },
  "api_cim_base_uri" => {
    type: "string",
    default: "https://barcoo.com/"
  },
  "api_cim_notifications_base_uri" => {
    type: "string",
    default: "https://notifications.barcoo.com/notifications/"
  },
  "rate_app_app_uri" => {
    type: "string",
    default: "market://details?id=%s"
  },
  "rate_app_browser_uri" => {
    type: "string",
    default: "http://play.google.com/store/apps/details?id=%s"
  },
  "appcenter_crash_reporting" => {
    type: "bool",
    default: "false"
  },
  "appcenter_id" => {
    type: "string",
    max_level: :brand_build,
    default: "",
    "barcooDebug" => {
      default: "7fa607e6-67aa-40ba-be6b-bbd0dd5814f0"
    },
    "barcooBeta" => {
      default: "a1e04698-41c7-419c-9364-d0b8cef8c844"
    },
    "ofertolinoDebug" => {
      default: "a1e04698-41c7-419c-9364-d0b8cef8c845"
    },
    "ofertolino" => {
      default: "a1e04698-41c7-419c-9364-d0b8cef8c845"
    },
    "marktjagdDebug" => {
      default: "53fcd134-9b7f-ba7a-ea58-1c71ddc8303c"
    },
    "marktjagdBeta" => {
      default: "b06a1f79-9660-ec23-df05-c2970765f8d6"
    },
    "offeristafrDebug" => {
      default: "6d2a093f-7d83-481f-8387-44284898e03d"
    },
    "offeristafrBeta" => {
      default: "3d712c23-d140-4e71-9895-3c3f0c1691f1"
    },
    "profitalDebug" => {
      default: "a2fedfab-72e7-4295-8900-bcc50ab72b56"
    },
    "profitalBeta" => {
      default: "e2a46cbb-9671-49c8-b502-a0c5db51e519"
    },
    "wogibtswasDebug" => {
      default: "ec9492cd-96f7-4953-9691-197e643f1b38"
    },
    "wogibtswasBeta" => {
      default: "0b30d421-9265-4d42-9e30-ff48d4792de2"
    },
    "wunderkaufDebug" => {
      default: "9a29c284-b6e9-4a5e-9069-e64a62e3629a"
    },
    "wunderkaufBeta" => {
      default: "4e3dd779-549d-4a67-9014-16ecc4fa989b"
    }
  },
  "firebase_application_id" => {
    type: "string",
    max_level: :brand_build,
    "barcooDebug" => {
      default: "1:175480501998:android:93831b01dee2ee3b7ba5ff"
    },
    "barcooBeta" => {
      default: "1:175480501998:android:1ee3d3b5b3efaef97ba5ff"
    },
    "barcooRelease" => {
      default: "1:175480501998:android:7ea7213d4c64e6a7"
    },
    "ofertolinoDebug" => {
      default: "1:175480501998:android:93831b01dee2ee3b7ba5fa"
    },
    "ofertolinoBeta" => {
      default: "1:175480501998:android:1ee3d3b5b3efaef97ba5fa"
    },
    "ofertolinoRelease" => {
      default: "1:175480501998:android:7ea7213d4c64e6a8"
    },
    "marktjagdDebug" => {
      default: "1:458164796592:android:57c1224916dad2bc79cf75"
    },
    "marktjagdBeta" => {
      default: "1:458164796592:android:d4b2793bc35399f279cf75"
    },
    "marktjagdRelease" => {
      default: "1:458164796592:android:e91a3e8eff028c40"
    },
    "offeristafrDebug" => {
      default: "1:508790666785:android:14ca74ecad1ab7604e5560"
    },
    "offeristafrBeta" => {
      default: "1:508790666785:android:f461ee37e492fdcb4e5560"
    },
    "offeristafrRelease" => {
      default: "1:508790666785:android:4c136a66dfd861ea"
    },
    "profitalDebug" => {
      default: "1:488289423818:android:6050a2d154671a4229bf33"
    },
    "profitalBeta" => {
      default: "1:488289423818:android:4d4b050e621e419129bf33"
    },
    "profitalRelease" => {
      default: "1:488289423818:android:8b2f378975f43b8d"
    },
    "wogibtswasDebug" => {
      default: "1:733749144954:android:6964087eb6fe438f"
    },
    "wogibtswasBeta" => {
      default: "1:733749144954:android:9381d73ef94d23448a7ac3"
    },
    "wogibtswasRelease" => {
      default: "1:733749144954:android:5d727938b2b5b4d5"
    },
    "wunderkaufDebug" => {
      default: "1:784732325277:android:c34bdbb7e97ee891e45b74"
    },
    "wunderkaufBeta" => {
      default: "1:784732325277:android:1800a149e4d61b37e45b74"
    },
    "wunderkaufRelease" => {
      default: "1:784732325277:android:d231c8736ba1344f"
    }
  },
  "firebase_project_id" => {
    type: "string",
    max_level: :brand,
    "barcoo" => {
      default: "secret-argon-504"
    },
    "ofertolino" => {
      default: "secret-argon-505"
    },
    "marktjagd" => {
      default: "marktjagd---android---prod"
    },
    "offeristafr" => {
      default: "offerista-fr"
    },
    "profital" => {
      default: "profital-170723"
    },
    "wogibtswas" => {
      default: "api-project-733749144954"
    },
    "wunderkauf" => {
      default: "api-project-784732325277"
    }
  },
  "firebase_api_key" => {
    type: "string",
    max_level: :brand_build
  },
  "gcm_defaultSenderId" => {
    type: "string",
    max_level: :brand,
    "barcoo" => {
      default: "175480501998"
    },
    "ofertolino" => {
      default: "175480501999"
    },
    "marktjagd" => {
      default: "458164796592"
    },
    "offeristafr" => {
      default: "508790666785"
    },
    "profital" => {
      default: "488289423818"
    },
    "wogibtswas" => {
      default: "733749144954"
    },
    "wunderkauf" => {
      default: "784732325277"
    }
  },
  "google_maps_api_key" => {
    type: "string"
  },
  "appsflyer_api_token" => {
    type: "string",
    max_level: :brand
  },
  "start_screen_ad_unit_id" => {
    type: "string",
    max_level: :brand,
    default: "",
    "barcoo" => {
      default: "/267717662/de_barcoo_app/de_barcoo_android_startscreenhero"
    },
    "barcooDebug" =>  {
      default: "/267717662/AppMjStartscreenHeroTEST"
    },
    "marktjagd" => {
      default: "/267717662/de_marktjagd_app/de_marktjagd_android_startscreenhero"
    },
    "marktjagdDebug" => {
      default: "/267717662/AppMjStartscreenHeroTEST"
    },
    "wogibtswas" => {
      default: "/267717662/AT_WGW_App/AT_WGW_Android_StartscreenHero"
    },
    "wogibtswasDebug" => {
      default: "/267717662/AppMjStartscreenHeroTEST"
    },
    "wunderkauf" => {
      default: "/267717662/de_wunderkauf_app/de_wunderkauf_android_startscreenhero"
    },
    "wunderkaufDebug" => {
      default: "/267717662/AppMjStartscreenHeroTEST"
    }
  },
  "start_screen_template_id" => {
    type: "string",
    default: "10112422"
  },
  "dfp_banner_popular_brochures_list_1" => {
    type: "string",
    max_level: :brand,
    default: "",
    "barcoo" => {
      default: "/267717662/de_barcoo_app/de_barcoo_android_popularbrochurestream_pos1"
    },
    "barcooDebug" =>  {
      default: "/267717662/AppBannerPopularBrochuresOneTEST"
    },
    "marktjagd" => {
      default: "/267717662/de_marktjagd_app/de_marktjagd_android_popularbrochurestream_pos1"
    },
    "marktjagdDebug" => {
      default: "/267717662/AppBannerPopularBrochuresOneTEST"
    },
    "profital" => {
      default: "/21679946410/AppBannerPopularBrochures"
    },
    "profitalDebug" => {
      default: "/267717662/AppBannerPopularBrochuresOneTEST"
    },
    "wogibtswas" => {
      default: "/267717662/AT_WGW_App/at_wgw_android_popularbrochurestream_pos1"
    },
    "wogibtswasDebug" => {
      default: "/267717662/AppBannerPopularBrochuresOneTEST"
    },
    "wunderkauf" => {
      default: "/267717662/de_wunderkauf_app/de_wunderkauf_android_popularbrochurestream_pos1"
    },
    "wunderkaufDebug" => {
      default: "/267717662/AppBannerPopularBrochuresOneTEST"
    }
  },
  "dfp_banner_popular_brochures_list_2" => {
    type: "string",
    max_level: :brand,
    default: "",
    "barcoo" => {
      default: "/267717662/de_barcoo_app/de_barcoo_android_popularbrochurestream_pos2"
    },
    "barcooDebug" =>  {
      default: "/267717662/AppBannerPopularBrochuresTwoTEST"
    },
    "marktjagd" => {
      default: "/267717662/de_marktjagd_app/de_marktjagd_android_popularbrochurestream_pos2"
    },
    "marktjagdDebug" => {
      default: "/267717662/AppBannerPopularBrochuresTwoTEST"
    },
    "profital" => {
      default: "/21679946410/AppBannerPopularBrochures"
    },
    "profitalDebug" => {
      default: "/267717662/AppBannerPopularBrochuresTwoTEST"
    },
    "wogibtswas" => {
      default: "/267717662/AT_WGW_App/at_wgw_android_popularbrochurestream_pos2"
    },
    "wogibtswasDebug" => {
      default: "/267717662/AppBannerPopularBrochuresTwoTEST"
    },
    "wunderkauf" => {
      default: "/267717662/de_wunderkauf_app/de_wunderkauf_android_popularbrochurestream_pos2"
    },
    "wunderkaufDebug" => {
      default: "/267717662/AppBannerPopularBrochuresTwoTEST"
    }
  },
  "dfp_banner_popular_brochures_list_3" => {
    type: "string",
    max_level: :brand,
    default: "",
    "barcoo" => {
      default: "/267717662/de_barcoo_app/de_barcoo_android_popularbrochurestream_pos3"
    },
    "barcooDebug" =>  {
      default: "/267717662/AppBannerPopularBrochuresThreeTEST"
    },
    "marktjagd" => {
      default: "/267717662/de_marktjagd_app/de_marktjagd_android_popularbrochurestream_pos3"
    },
    "marktjagdDebug" => {
      default: "/267717662/AppBannerPopularBrochuresThreeTEST"
    },
    "profital" => {
      default: "/21679946410/AppBannerPopularBrochures"
    },
    "profitalDebug" => {
      default: "/267717662/AppBannerPopularBrochuresThreeTEST"
    },
    "wogibtswas" => {
      default: "/267717662/AT_WGW_App/at_wgw_android_popularbrochurestream_pos3"
    },
    "wogibtswasDebug" => {
      default: "/267717662/AppBannerPopularBrochuresThreeTEST"
    },
    "wunderkauf" => {
      default: "/267717662/de_wunderkauf_app/de_wunderkauf_android_popularbrochurestream_pos3"
    },
    "wunderkaufDebug" => {
      default: "/267717662/AppBannerPopularBrochuresThreeTEST"
    }
  },
  "dfp_banner_new_brochures_list_1" => {
    type: "string",
    max_level: :brand,
    default: "",
    "barcoo" => {
      default: "/267717662/de_barcoo_app/de_barcoo_android_newbrochurestream_pos1"
    },
    "barcooDebug" =>  {
      default: "/267717662/AppBannerNewBrochuresOneTEST"
    },
    "marktjagd" => {
      default: "/267717662/de_marktjagd_app/de_marktjagd_android_newbrochurestream_pos1"
    },
    "marktjagdDebug" => {
      default: "/267717662/AppBannerNewBrochuresOneTEST"
    },
    "profital" => {
      default: "/21679946410/AppBannerNewBrochures"
    },
    "profitalDebug" => {
      default: "/267717662/AppBannerNewBrochuresOneTEST"
    },
    "wogibtswas" => {
      default: "/267717662/at_wgw_app/at_wgw_android_newbrochurestream_pos1"
    },
    "wogibtswasDebug" => {
      default: "/267717662/AppBannerNewBrochuresOneTEST"
    },
    "wunderkauf" => {
      default: "/267717662/de_wunderkauf_app/de_wunderkauf_android_newbrochurestream_pos1"
    },
    "wunderkaufDebug" => {
      default: "/267717662/AppBannerNewBrochuresOneTEST"
    }
  },
  "dfp_banner_new_brochures_list_2" => {
    type: "string",
    max_level: :brand,
    default: "",
    "barcoo" => {
      default: "/267717662/de_marktjagd_app/de_marktjagd_android_newbrochurestream_pos2"
    },
    "barcooDebug" =>  {
      default: "/267717662/AppBannerNewBrochuresTwoTEST"
    },
    "marktjagd" => {
      default: "/267717662/de_marktjagd_app/de_marktjagd_android_newbrochurestream_pos2"
    },
    "marktjagdDebug" => {
      default: "/267717662/AppBannerNewBrochuresTwoTEST"
    },
    "profital" => {
      default: "/21679946410/AppBannerNewBrochures"
    },
    "profitalDebug" => {
      default: "/267717662/AppBannerNewBrochuresTwoTEST"
    },
    "wogibtswas" => {
      default: "/267717662/at_wgw_app/at_wgw_android_newbrochurestream_pos2"
    },
    "wogibtswasDebug" => {
      default: "/267717662/AppBannerNewBrochuresTwoTEST"
    },
    "wunderkauf" => {
      default: "/267717662/de_wunderkauf_app/de_wunderkauf_android_newbrochurestream_pos2"
    },
    "wunderkaufDebug" => {
      default: "/267717662/AppBannerNewBrochuresTwoTEST"
    }
  },
  "dfp_banner_new_brochures_list_3" => {
    type: "string",
    max_level: :brand,
    default: "",
    "barcoo" => {
      default: "/267717662/de_barcoo_app/de_barcoo_android_newbrochurestream_pos3"
    },
    "barcooDebug" =>  {
      default: "/267717662/AppBannerNewBrochuresThreeTEST"
    },
    "marktjagd" => {
      default: "/267717662/de_marktjagd_app/de_marktjagd_android_newbrochurestream_pos3"
    },
    "marktjagdDebug" => {
      default: "/267717662/AppBannerNewBrochuresThreeTEST"
    },
    "profital" => {
      default: "/21679946410/AppBannerNewBrochures"
    },
    "profitalDebug" => {
      default: "/267717662/AppBannerNewBrochuresThreeTEST"
    },
    "wogibtswas" => {
      default: "/267717662/at_wgw_app/at_wgw_android_newbrochurestream_pos3"
    },
    "wogibtswasDebug" => {
      default: "/267717662/AppBannerNewBrochuresThreeTEST"
    },
    "wunderkauf" => {
      default: "/267717662/de_wunderkauf_app/de_wunderkauf_android_newbrochurestream_pos3"
    },
    "wunderkaufDebug" => {
      default: "/267717662/AppBannerNewBrochuresThreeTEST"
    }
  },
  "dfp_banner_psp" => {
    type: "string",
    max_level: :brand,
    default: "",
    "barcoo" => {
      default: "/267717662/de_barcoo_app/de_barcoo_android_scanresultpage"
    },
    "barcooDebug" => {
      default: "/267717662/AppBannerPSPTEST"
    }
  },
  "dfp_banner_brochure" => {
    type: "string",
    max_level: :brand,
    default: "",
    "barcoo" => {
      default: "/267717662/DE_Barcoo_Android_BrochureDetail"
    },
    "barcooDebug" =>  {
      default: "/267717662/AppBannerBrochureDetailTEST"
    },
    "marktjagd" => {
      default: "/267717662/DE_Marktjagd_Android_BrochureDetail"
    },
    "marktjagdDebug" => {
      default: "/267717662/AppBannerBrochureDetailTEST"
    },
    "wogibtswas" => {
      default: "/267717662/AT_WGW_App/AT_WGW_Android_BrochureDetail"
    },
    "wogibtswasDebug" => {
      default: "/267717662/AppBannerBrochureDetailTEST"
    },
    "wunderkauf" => {
      default: "/267717662/DE_Wunderkauf_Android_BrochureDetail"
    },
    "wunderkaufDebug" => {
      default: "/267717662/AppBannerBrochureDetailTEST"
    }
  }
}

def fetch_default(variant, parent_variants, opts)
  opts.dig(variant, :default) ||
    parent_variants.map {|variant| opts.dig(variant, :default) }.compact.first ||
    opts[:default]
end

def prompt(level, variant, parent_variants, key, opts, secrets)
  print "#{key} >> #{variant}"
  default = fetch_default(variant, parent_variants, opts)
  print " [#{default}]" if default
  required =  default.nil? && level == opts.fetch(:max_level, :main)
  cache = secrets.dig(variant, key) if required
  print " [#{cache}]" if cache
  print " (required)" if required && !cache
  print ": "

  value = gets.chomp

  if value.empty?
    if required
      return cache if cache
      puts "You must provide a value for #{key} in #{variant}!"
      prompt(level, variant, parent_variants, key, opts, secrets)
    else
      default
    end
  else
    secrets[variant] ||= {}
    secrets[variant][key] = value if required
    value
  end
end

def expand_placeholders(value, *lookup_tables)
  value&.gsub(/%%([^%]+)%%/) {|placeholder|
    key = $1
    table = lookup_tables.find {|t| t[key] }
    (table && table[key]) || placeholder
  }
end

puts "Enter configuration values. Values in [] are defaults."
puts "Entries marked with (required) have to be non-empty."
puts "Entering no value when there's no default and (required) marking skips overriding the value at the displayed level."
puts "In doubt steal configuration values from Bitrise configuration."
puts

expanded_configs = Hash.new {|h, k| h[k] = {} }
secrets = File.exists?(SECRETS_CACHE_FILE) ? JSON.parse(File.read(SECRETS_CACHE_FILE)) : {}

# Prompt secrets and deviations

CONFIGS.each do |config_key, config_opts|
  expanded_configs["main"][config_key] = prompt(:main, "main", [], config_key, config_opts, secrets) if config_opts.fetch(:max_level, :main) == :main

  BUILDS.each do |build|
    expanded_configs[build][config_key] = prompt(:build, build, ["main"], config_key, config_opts, secrets) if %i(main build).include?(config_opts.fetch(:max_level, :main))
  end

  BRANDS.each do |brand|
    expanded_configs[brand][config_key] = prompt(:brand, brand, ["main"], config_key, config_opts, secrets) if %i(main brand).include?(config_opts.fetch(:max_level, :main))

    BUILDS.each do |build|
      variant = "#{brand}#{build.capitalize}"
      expanded_configs[variant][config_key] = prompt(:brand_build, variant, [brand, build, "main"], config_key, config_opts, secrets)
    end
  end
end

File.write(SECRETS_CACHE_FILE, secrets.to_json)

# Cleanup and expand placeholders

expanded_configs["main"].transform_values! {|value| expand_placeholders(value, expanded_configs["main"]) }

BUILDS.each do |build|
  expanded_configs[build].transform_values! {|value| expand_placeholders(value, expanded_configs[build], expanded_configs["main"]) }
  expanded_configs[build].reject! {|key, value| expanded_configs["main"][key] == value }
end

BRANDS.each do |brand|
  expanded_configs[brand].transform_values! {|value| expand_placeholders(value, expanded_configs[brand], expanded_configs["main"]) }
  expanded_configs[brand].reject! {|key, value| expanded_configs["main"][key] == value }

  BUILDS.each do |build|
    variant = "#{brand}#{build.capitalize}"
    expanded_configs[variant].transform_values! {|value|
      expand_placeholders(value, expanded_configs[variant], expanded_configs[build], expanded_configs[brand], expanded_configs["main"])
    }
    expanded_configs[variant].reject! {|key, value|
      expanded_configs[brand][key] == value || expanded_configs[build][key] == value ||
        (expanded_configs[brand][key].nil? && expanded_configs[build][key].nil? && expanded_configs["main"][key] == value)
    }
  end
end

expanded_configs.transform_values!(&:compact)
expanded_configs.compact!

# Render configs

expanded_configs.each do |variant, config|
  path = "app/src/#{variant}/res/values/config.xml"

  xml = TEMPLATE % config.map {|key, value|
    type = CONFIGS[key][:type]
    %(  <#{type} name="#{key}">#{value}</#{type}>)
  }.join("\n")

  FileUtils.mkdir_p File.dirname(path)
  File.write path, xml

  puts "Written #{path}."
end
