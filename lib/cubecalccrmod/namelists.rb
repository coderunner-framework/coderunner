{:cubecalc=>
  {:description=>"",
   :should_include=>"true",
   :variables=>
    {:calculate_sides=>
      {:should_include=>"true",
       :description=>nil,
       :help=>nil,
       :code_name=>:calculate_sides,
       :must_pass=>
        [{:test=>"kind_of? Integer",
          :explanation=>"This variable must be an integer."}],
       :type=>:Integer,
       :autoscanned_defaults=>[0]},
     :must_sleep=>
      {:should_include=>"true",
       :description=>nil,
       :help=>nil,
       :code_name=>:must_sleep,
       :must_pass=>
        [{:test=>"kind_of? Integer",
          :explanation=>"This variable must be an integer."}],
       :type=>:Integer,
       :autoscanned_defaults=>[0]},
     :width=>
      {:should_include=>"true",
       :description=>nil,
       :help=>nil,
       :code_name=>:width,
       :must_pass=>
        [{:test=>"kind_of? Numeric",
          :explanation=>
           "This variable must be a floating point number (an integer is also acceptable: it will be converted into a floating point number)."}],
       :type=>:Float,
       :autoscanned_defaults=>[1.0]},
     :depth=>
      {:should_include=>"true",
       :description=>nil,
       :help=>nil,
       :code_name=>:depth,
       :must_pass=>
        [{:test=>"kind_of? Numeric",
          :explanation=>
           "This variable must be a floating point number (an integer is also acceptable: it will be converted into a floating point number)."}],
       :type=>:Float,
       :autoscanned_defaults=>[1.0]},
     :height=>
      {:should_include=>"true",
       :description=>nil,
       :help=>nil,
       :code_name=>:height,
       :must_pass=>
        [{:test=>"kind_of? Numeric",
          :explanation=>
           "This variable must be a floating point number (an integer is also acceptable: it will be converted into a floating point number)."}],
       :type=>:Float,
       :autoscanned_defaults=>[1.0]},
     :dummy_for_arrays=>
      {:should_include=>"true",
       :description=>"",
       :help=>"",
       :code_name=>:dummy_for_arrays,
       :must_pass=>
        [{:test=>"kind_of? Numeric",
          :explanation=>
           "This variable must be a floating point number (an integer is also acceptable: it will be converted into a floating point number)."}],
       :type=>:Float,
       :autoscanned_defaults=>[1.0]},
     :dummy_complex=>
      {:should_include=>"true",
       :description=>nil,
       :help=>nil,
       :code_name=>:dummy_complex,
       :must_pass=>
        [{:test=>"kind_of? Complex",
          :explanation=>"This variable must be a complex number."}],
       :type=>:Complex,
       :autoscanned_defaults=>[]}}},
 :parameters=>{:description=>"", :should_include=>"true", :variables=>{}},
 :kt_grids_knobs=>{:description=>"", :should_include=>"true", :variables=>{}},
 :kt_grids_single_parameters=>
  {:description=>"", :should_include=>"true", :variables=>{}},
 :theta_grid_parameters=>
  {:description=>"", :should_include=>"true", :variables=>{}},
 :theta_grid_knobs=>
  {:description=>"", :should_include=>"true", :variables=>{}},
 :theta_grid_salpha_knobs=>
  {:description=>"", :should_include=>"true", :variables=>{}},
 :le_grids_knobs=>{:description=>"", :should_include=>"true", :variables=>{}},
 :dist_fn_knobs=>{:description=>"", :should_include=>"true", :variables=>{}},
 :fields_knobs=>{:description=>"", :should_include=>"true", :variables=>{}},
 :knobs=>{:description=>"", :should_include=>"true", :variables=>{}},
 :reinit_knobs=>{:description=>"", :should_include=>"true", :variables=>{}},
 :layouts_knobs=>{:description=>"", :should_include=>"true", :variables=>{}},
 :collisions_knobs=>
  {:description=>"", :should_include=>"true", :variables=>{}},
 :nonlinear_terms_knobs=>
  {:description=>"", :should_include=>"true", :variables=>{}},
 :species_knobs=>{:description=>"", :should_include=>"true", :variables=>{}}}
