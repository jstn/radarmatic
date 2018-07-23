class Radarmatic {
  constructor() {
    $(document).on("ready", this.get_ready_to_rumble.bind(this));
  }

  storage_or_default(key, def) {
    const item = window.localStorage.getItem(key);
    return item ? item : def;
  }

  get_ready_to_rumble() {
    if ($("#radarmatic_map").length < 1) { return; }

    this.image = null;
    this.time = (new Date).getTime();
    this.product_nexrad = "N0Q";
    this.product_tdwr = "TZL";
    this.current_site = this.storage_or_default("current_site", "KDIX");
    this.create_sites();
    this.create_map();
    this.create_gl();
    this.create_ui();
    this.get_image(this.current_site);
  }

  create_sites() {
    this.sites = {};
    for (const call_sign in RadarmaticSites) {
      const site = RadarmaticSites[call_sign];
      this.sites[call_sign] = {
        name: site["name"],
        ele: site["ele"],
        tdwr: site["tdwr"],
        loc: new L.LatLng(site.lat, site.lng)
      }
    }
  }

  create_map() {
    this.map = new L.Map("radarmatic_map", {
      center: this.sites[this.current_site].loc,
      zoom: 8
    });

    this.map_layers = {
      "Toner": new L.StamenTileLayer("toner"),
      "Toner Lite": new L.StamenTileLayer("toner-lite"),
      "Toner BG": new L.StamenTileLayer("toner-background")
    }

    if (window.devicePixelRatio > 1) {
      for (let name in this.map_layers) {
        const layer = this.map_layers[name];
        layer._url = layer._url.replace(/\.(?!.*\.)/, "@2x.");
      }
    }

    this.map.addLayer(this.map_layers["Toner"]);
    L.control.layers(this.map_layers).addTo(this.map);

    for (const evnt of ["load", "move", "zoom", "resize", "viewreset"]) {
      this.map.on(evnt, this.render.bind(this));
      this.map.on(evnt, this.find_nearest_radar.bind(this));
    }
  }

  create_gl() {
    this.material = new THREE.ShaderMaterial({
      uniforms: {
        u_time: { value: 0.0 },
        u_bins_per_radial: { value: 0.0 },
        u_pixel_ratio: { value: 0.0 },
        u_texture: { value: new THREE.Texture() },
        u_resolution: { value: new THREE.Vector2() },
        u_texture_size: { value: new THREE.Vector2() },
        u_radar_lat_lng: { value: new THREE.Vector2() },
        u_map_pixel_origin: { value: new THREE.Vector2() },
        u_map_pane_pos: { value: new THREE.Vector2() },
        u_map_zoom: { value: 0.0 },
        u_color_modifier: { value: 0.0 }
      },
      vertexShader: $("#vertex_shader").text(),
      fragmentShader: $("#fragment_shader").text()
    });

    this.scene = new THREE.Scene();
    this.geometry = new THREE.PlaneBufferGeometry(2, 2);
    this.mesh = new THREE.Mesh(this.geometry, this.material);
    this.scene.add(this.mesh);

    this.camera = new THREE.Camera();
    this.renderer = new THREE.WebGLRenderer({ alpha: true });
    this.renderer.setPixelRatio(window.devicePixelRatio);
    $("#radarmatic_map").append(this.renderer.domElement);
  }

  create_ui() {
    $("#opacity_slider").on("input", e => {
      $(this.renderer.domElement).css("opacity", $("#opacity_slider").val());
    });
    $("#color_slider").on("input", this.render.bind(this));
    $("#spin_slider").on("input", this.render.bind(this));
    $("#lock_checkbox").on("change", this.find_nearest_radar.bind(this));
  }

  find_nearest_radar() {
    if ($("#lock_checkbox").prop("checked")) { return; }

    this.map_center = this.map.getBounds().getCenter();
    let nearest = this.image.message_header.call_sign;
    let distance = 99999999;

    for (let call_sign in this.sites) {
      const loc = this.sites[call_sign].loc;
      const site_dist = this.map_center.distanceTo(loc);
      if (site_dist < distance) {
        nearest = call_sign;
        distance = site_dist;
      }
    }

    if (nearest !== this.image.message_header.call_sign) {
      this.current_site = nearest;
      window.localStorage.setItem("current_site", nearest);
      this.get_image(nearest);
    }
  }

  get_image(call_sign) {
    let product = this.sites[call_sign].tdwr ? this.product_tdwr : this.product_nexrad;

    $.getJSON(`/${call_sign}/${product}.json`, function(data) {
      if (call_sign !== this.current_site) { return; }
      this.image = data;
      this.update_texture_for_image();
      this.render();
    }.bind(this));
  }

  format_date(iso8601) {
    const d = new Date(iso8601);
    const year = d.getFullYear();
    let month = d.getMonth() + 1;
    if (month < 10) { month = `0${month}`; }
    let day = d.getDate();
    if (day < 10) { day = `0${day}`; }
    let hour = d.getHours();
    if (hour < 10) { hour = `0${hour}`; }
    let min = d.getMinutes();
    if (min < 10) { min = `0${min}`; }
    let sec = d.getSeconds();
    if (sec < 10) { sec = `0${sec}`; }
    return `${year}-${month}-${day} ${hour}:${min}:${sec}`;
  }

  update_texture_for_image() {
    const bins = window.atob(this.image.texture.base64);
    const bins_array = new Uint8Array(bins.length);
    for (let i = 0; i < bins.length; i++) {
      bins_array[i] = bins.charCodeAt(i);
    }

    const data = bins_array;
    const width = this.image.texture.width;
    const height = this.image.texture.height;
    const format = THREE.AlphaFormat;
    const type = THREE.UnsignedByteType;
    const map = THREE.UVMapping;
    const wS = THREE.ClampToEdgeWrapping;
    const wT = THREE.ClampToEdgeWrapping;
    const mag = THREE.NearestFilter;
    const min = THREE.NearestFilter;
    const anis = 1;

    this.image.texture = new THREE.DataTexture(data, width, height, format, type, map, wS, wT, mag, min, anis);
    this.image.texture.needsUpdate = true;
  }

  render() {
    if (!this.map || !this.renderer || !this.image) {
      return;
    }

    const w = $("#radarmatic_map").width();
    const h = $("#radarmatic_map").height();
    this.renderer.setSize(w, h);

    const po = this.map.getPixelOrigin();
    const mpp = L.DomUtil.getPosition(this.map.getPanes().mapPane);
    const now = (new Date).getTime();
    this.material.uniforms.u_time.value += ((now - this.time) / 1000);
    this.time = now;

    const call_sign = this.image.message_header.call_sign;
    const scan_time = this.image.product_description.volume_scan_time;
    $("#radar_name").html(`[${call_sign}] ${this.sites[call_sign].name}`);
    $("#radar_time").html(this.format_date(scan_time));

    this.material.uniforms.u_color_modifier.value = $("#color_slider").val();
    this.material.uniforms.u_texture.value = this.image.texture;
    this.material.uniforms.u_map_zoom.value = this.map.getZoom();
    this.material.uniforms.u_pixel_ratio.value = window.devicePixelRatio;
    this.material.uniforms.u_resolution.value.x = this.renderer.domElement.width;
    this.material.uniforms.u_resolution.value.y = this.renderer.domElement.height;
    this.material.uniforms.u_bins_per_radial.value = this.image.product_symbology.layers[0].number_of_range_bins;
    this.material.uniforms.u_map_pixel_origin.value.x = po.x;
    this.material.uniforms.u_map_pixel_origin.value.y = po.y;
    this.material.uniforms.u_map_pane_pos.value.x = mpp.x;
    this.material.uniforms.u_map_pane_pos.value.y = mpp.y;
    this.material.uniforms.u_radar_lat_lng.value.x = this.image.product_description.radar_latitude;
    this.material.uniforms.u_radar_lat_lng.value.y = this.image.product_description.radar_longitude;
    this.material.uniforms.u_texture_size.value.x = this.image.texture.image.width;
    this.material.uniforms.u_texture_size.value.y = this.image.texture.image.height;

    this.renderer.render(this.scene, this.camera);
  }
}

new Radarmatic();
