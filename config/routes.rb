constraints = {
  site: /[A-Z]{4}/,
  product: /[A-Z0-9]{3}/,
  range: /[0-9]{1,3},[0-9]{1,3}/
}

Rails.application.routes.draw do
  get  ":site/:product/:range",  to: "radar_images#range",  as: "radar_range",  constraints: constraints
  get  ":site/:product",         to: "radar_images#image",  as: "radar_image",  constraints: constraints
  root                           to: "maps#map"
end
