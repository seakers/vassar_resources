;; *****************
;; SYNERGY RULES (USED!)
;; *****************

;; ********
;; Generic synergy rules
;; ********

(defrule SYNERGIES::raz-synergy-levels
    (declare (salience 50))
    ?m <- (REQUIREMENTS::Measurement (synergy-level# nil))
    =>
    (modify ?m (synergy-level# 0))
    )

(defrule SYNERGIES::spatial-disaggregation
    "identifies a synergy where a frequently sampled measurement with low spatial resolution and a sparsely sampled measurement with high spatial resolution can be combined to produce a frequent measurement with high spatial resolution and average accuracy"
    ?m1 <- (REQUIREMENTS::Measurement (Parameter ?p&~nil) (Temporal-resolution ?tr1&~nil) (Horizontal-Spatial-Resolution ?hsr1&~nil) (Accuracy ?a1&~nil) (Id ?id1) (taken-by ?ins1) (synergy-level# ?s1&:(< ?s1 1)) (factHistory ?fh1))
    ?m2 <- (REQUIREMENTS::Measurement (Parameter ?p&~nil) (Temporal-resolution ?tr2&~nil) (Horizontal-Spatial-Resolution ?hsr2&~nil) (Accuracy ?a2&~nil) (Id ?id2) (taken-by ?ins2) (synergy-level# ?s2&:(< ?s2 1)) (factHistory ?fh2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (not (REASONING::stop-improving (Measurement ?p)))
    (test (eq (str-index disaggregated ?ins1) FALSE))
    (test (eq (str-index disaggregated ?ins2) FALSE))
    (test (eq (str-index syn ?ins1) FALSE))
    (test (eq (str-index syn ?ins2) FALSE))
    (test (neq ?id1 ?id2))

	=>
	(duplicate ?m1 (Parameter ?p) (Temporal-resolution (eval (fuzzy-max Temporal-resolution ?tr1 ?tr2))) 
            (Horizontal-Spatial-Resolution (eval (fuzzy-max Horizontal-Spatial-Resolution ?hsr1 ?hsr2))) 
            (Accuracy (eval (fuzzy-avg ?a1 ?a2))) (synergy-level# (+ (max ?s1 ?s2) 1)) 
            (Id (str-cat ?id1 "-disaggregated" ?id2))
            (taken-by (str-cat ?ins1 "-" ?ins2 "-disaggregated"))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::spatial-disaggregation) " D" (call ?m1 getFactId) " S" (call ?m2 getFactId) "}")))
    
    (duplicate ?m2 (Parameter ?p) (Temporal-resolution (eval (fuzzy-max Temporal-resolution ?tr1 ?tr2))) 
            (Horizontal-Spatial-Resolution (eval (fuzzy-max Horizontal-Spatial-Resolution ?hsr1 ?hsr2))) 
            (Accuracy (eval (fuzzy-avg ?a1 ?a2))) (synergy-level# (+ (max ?s1 ?s2) 1)) 
            (Id (str-cat ?id2 "-disaggregated" ?id1))
            (taken-by (str-cat ?ins2 "-" ?ins1 "-disaggregated"))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::spatial-disaggregation) " D" (call ?m2 getFactId) " S" (call ?m1 getFactId) "}")))
)

(defrule SYNERGIES::spatial-disaggregation-hyperspectral
    "identifies a synergy between a hyperspectral coarse spatial resolution measurement and a multispectral high spatial resolution measurement, which can be combined to produce a high spatial resolution hyperspectral measurement with lower accuracy, and uses fuzzy logic equations to adjust temporal and spatial resolutions, and calculate the average accuracy of the resulting measurement"
    ?m1 <- (REQUIREMENTS::Measurement (Parameter ?p&~nil) (Temporal-resolution ?tr1&~nil) (Spectral-sampling Multispectral-10-100-channels) (Horizontal-Spatial-Resolution ?hsr1&~nil) (Accuracy ?a1&~nil) (Id ?id1) (taken-by ?ins1) (synergy-level# ?s1&:(< ?s1 1)) (factHistory ?fh1))
    ?m2 <- (REQUIREMENTS::Measurement (Parameter ?p&~nil) (Temporal-resolution ?tr2&~nil) (Spectral-sampling Hyperspectral-100-channels-or-more) (Horizontal-Spatial-Resolution ?hsr2&~nil) (Accuracy ?a2&~nil) (Id ?id2) (taken-by ?ins2) (synergy-level# ?s2&:(< ?s2 1)) (factHistory ?fh2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (not (REASONING::stop-improving (Measurement ?p)))
    (test (eq (str-index disaggregated ?ins1) FALSE))
    (test (eq (str-index disaggregated ?ins2) FALSE))
    (test (neq ?id1 ?id2))

	=>

    (duplicate ?m1 (Temporal-resolution (eval (fuzzy-max Temporal-resolution ?tr1 ?tr2))) 
            (Horizontal-Spatial-Resolution (eval (fuzzy-max Horizontal-Spatial-Resolution ?hsr1 ?hsr2))) 
            (Accuracy (eval (fuzzy-avg ?a1 ?a2))) (synergy-level# (+ (max ?s1 ?s2) 1))
            (Spectral-sampling Hyperspectral-100-channels-or-more)
            (Id (str-cat ?id1 "-hyp-disaggregated-" ?id2))
            (taken-by (str-cat ?ins1 "-" ?ins2 "-hyp-disaggregated")) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::spatial-disaggregation-hyperspectral) " D" (call ?m1 getFactId) " S" (call ?m2 getFactId) "}")))
)

(defrule SYNERGIES::spatial-averaging
    "identifies a synergy where any image can be spatially averaged to provide a new, coarser resolution image with better accuracy, given that the same or better horizontal-spatial-resolution (HSR) is maintained at a low range (1km-10km) and high accuracy is maintained"
    ?m <- (REQUIREMENTS::Measurement (Parameter ?p&~nil)  (Horizontal-Spatial-Resolution ?hsr1&~nil) (Accuracy ?a2&~nil) (Id ?id1) (taken-by ?ins1) (synergy-level# ?s1&:(< ?s1 1)))
    (test (>= (SameOrBetter Horizontal-Spatial-Resolution ?hsr1 Low-1km-10km) 0))
    (test (>= (SameOrBetter Accuracy High ?a2) 1))
    (not (REASONING::stop-improving (Measurement ?p)))
	=>
    ; (printout t "worth-improving " (worth-improving-measurement ?p) crlf)
    (duplicate ?m (Id (str-cat ?id1 "-space-averaged")) (Horizontal-Spatial-Resolution (eval (Worsen Horizontal-Spatial-Resolution ?hsr1))) (Accuracy (eval (Improve Accuracy ?a2))) (taken-by (str-cat ?ins1 "-space-averaged")) (synergy-level# (+ ?s1 1)) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::spatial-averaging) " D" (call ?m getFactId) "}")))
)

(defrule SYNERGIES::time-averaging
    "identifies that any image can be averaged out in time to provide a new, better accuracy, sparser temporal resolution image"
    ?m <- (REQUIREMENTS::Measurement (Parameter ?p&~nil)  (Temporal-resolution# ?tr1&~nil) 
        (rms-variable-measurement# ?rms&:(> ?rms )) (Id ?id1) (taken-by ?ins1) (synergy-level# ?s1&:(< ?s1 1)))
    (test (>= (SameOrBetter Temporal-resolution ?tr1 Low-3days-1-week) 0))
    (test (>= (SameOrBetter Accuracy High ?rms) 1))
    (not (REASONING::stop-improving (Measurement ?p)))
	=>
    (duplicate ?m (Id (str-cat ?id1 "-time-averaged")) (Temporal-resolution (eval (Worsen Temporal-resolution ?tr1))) (Accuracy (eval (Improve Accuracy ?a2))) (taken-by (str-cat ?ins1 "-time-averaged")) (synergy-level# (+ ?s1 1)) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::time-averaging) " D" (call ?m getFactId) "}")))
)


    
    
;; **********************
;; Emergent measurements and data products
;; **********************

(defrule SYNERGIES::seafloor-topography 
    "identifies that seafloor topography measurements can be estimated by combining sea level height and ocean mass distribution measurements"
    ?slh <- (REQUIREMENTS::Measurement (Parameter "3.2.1 Sea level height") (Id ?id1))
    ?grv <- (REQUIREMENTS::Measurement (Parameter "3.2.6 Ocean mass distribution") (Id ?id2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
       
    =>
    (duplicate ?slh (Id (str-cat ?id1 "-syn-" ?id2)) (Parameter "3.2.2 seafloor topography") (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::seafloor-topography) " D" (call ?slh getFactId) " S" (call ?grv getFactId) "}"))  ))

;; river plumes and sediment fluxes from ocean color
(defrule SYNERGIES::river-plumes-from-ocean-color
    "identifies a synergy between ocean color measurements of sufficient horizontal spatial resolution and extended ocean color measurements for the measurement of river plumes and sediment fluxes"
        ?oc <- (REQUIREMENTS::Measurement (Parameter "3.1.1 Ocean color - 410-680nm (Chlorophyll absorption and fluorescence, pigments, phytoplankton, CDOM)") (Horizontal-Spatial-Resolution ?hsr & :(neq ?hsr nil)) (Id ?id1) (Temporal-resolution ?tr))
    (test (SameOrBetter Horizontal-Spatial-Resolution ?hsr High-10-100m))
    (test (SameOrBetter Temporal-resolution ?tr High-12h-24h))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "3.1.2 Extended ocean color - UV (enhanced DOC, CDOM)") (Horizontal-Spatial-Resolution ?hsr & :(neq ?hsr nil)) (Id ?id2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    =>
    (duplicate ?oc (Id (str-cat ?id1 "-syn")) (Parameter "3.2.5 river plumes/sediment fluxes")  (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::river-plumes-from-ocean-color) " D" (call ?oc getFactId) " S" (call ?sub getFactId) "}")) ))

;; hydrocarbon monitoring from surface deformation and surface composition (SAR)
(defrule SYNERGIES::hydrocarbon-reservoir-monitoring-from-surface-deformation
    "identifies a synergy between monitoring hydrocarbon reservoirs by measuring surface deformation and surface composition, with the surface deformation parameter having a horizontal spatial resolution that is the same or better than High-10-100m, and the surface composition parameter being cross-registered with the same measurements as the surface deformation parameter"
        ?sd <- (REQUIREMENTS::Measurement (Parameter "2.2.1 surface deformation") (Horizontal-Spatial-Resolution ?hsr & :(neq ?hsr nil)) (Id ?id1))
    (test (SameOrBetter Horizontal-Spatial-Resolution ?hsr High-10-100m))
    ?sub <-(REQUIREMENTS::Measurement (Parameter "2.6.5 surface composition") (Horizontal-Spatial-Resolution ?hsr & :(neq ?hsr nil)) (Id ?id2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    =>
    (duplicate ?sd (Id (str-cat ?id1 "-syn-" ?id2)) (Parameter "2.6.4 hydrocarbon reservoir monitoring") (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::hydrocarbon-reservoir-monitoring-from-surface-deformation) " D" (call ?sd getFactId) " S" (call ?sub getFactId) "}"))  ))

;; flood monitoring from hi res topography (lidar)
(defrule SYNERGIES::flood-monitoring-from-hires-topography
    "states that high-resolution topography with 5m horizontal spatial resolution and 10cm accuracy can be used for flood monitoring"
        ?topo <-  (REQUIREMENTS::Measurement (Parameter "2.2.2 Hi-res topography") (Horizontal-Spatial-Resolution ?hsr & :(neq ?hsr nil)) (Id ?id1) )
    (test (SameOrBetter Horizontal-Spatial-Resolution ?hsr Very-high-1-10m))
    =>
    (duplicate ?topo (Id (str-cat ?id1 "-syn")) (Parameter "2.6.4 hydrocarbon reservoir monitoring") (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::flood-monitoring-from-hires-topography) " D" (call ?topo getFactId) "}"))))

;; groundwater storage from gravity measurement
(defrule SYNERGIES::groundwater-storage-from-gravity
    "infers the groundwater storage from precise gravity measurements and creates a corresponding new measurement fact"
        ?grav <- (REQUIREMENTS::Measurement (Parameter "5.1.1 Geoid and gravity field variations") (Horizontal-Spatial-Resolution ?hsr & :(neq ?hsr nil)) (Id ?id1))
    =>
    (duplicate ?grav (Id (str-cat ?id1 "-syn")) (Parameter "2.7.3 groundwater storage") (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::groundwater-storage-from-gravity) " D" (call ?grav getFactId) "}")) ))

;; glacier mass balance from gravity measurement
(defrule SYNERGIES::glacier-mass-balance-from-gravity
    "states that mass balance measurements can be inferred from precise gravity measurements using ice topography measurements"
        ?grav <- (REQUIREMENTS::Measurement (Parameter "5.1.1 Geoid and gravity field variations") (Horizontal-Spatial-Resolution ?hsr & :(neq ?hsr nil)) (taken-by ?ins1) (Id ?id1))
    	?topo <- (REQUIREMENTS::Measurement (Parameter "4.1.5 Ice Sheet topography") (Id ?id2) (taken-by ?ins2))
    	(SYNERGIES::cross-registered (measurements $?m))
    	(test (member$ ?id1 $?m))
    	(test (member$ ?id2 $?m))
    =>
    (duplicate ?topo (Id (str-cat ?id1 "-syn" ?id2)) (taken-by (str-cat ?ins1 "-syn" ?ins2)) (Parameter "4.1.3 glacier mass balance")(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::glacier-mass-balance-from-gravity) " D" (call ?topo getFactId) " S" (call ?grav getFactId) "}"))))

;; ocean mass distribution from gravity measurement
(defrule SYNERGIES::ocean-mass-distribution-from-gravity
    "states that precise gravity measurements can be used to infer the distribution of ocean mass, and creates a new measurement fact for 'ocean mass distribution'"
        ?grav <- (REQUIREMENTS::Measurement (Parameter "5.1.1 Geoid and gravity field variations") (Horizontal-Spatial-Resolution ?hsr & :(neq ?hsr nil)) (Id ?id1))
    =>
    (duplicate ?grav (Id (str-cat ?id1 "-syn")) (Parameter "3.2.6 Ocean mass distribution") (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::ocean-mass-distribution-from-gravity) " D" (call ?grav getFactId) ))))

; 1.8.16 Visible atmospheric plumes from aerosol measurement?
(defrule SYNERGIES::visible-atmospheric-plume-from-aerosols
    "identifies the synergy between high temporal and spatial resolution multispectral aerosol measurements and visible atmospheric plumes measurements, and duplicates the aerosol measurement with a new measurement parameter for visible atmospheric plumes"
        ?ae <- (REQUIREMENTS::Measurement (Parameter "1.1.1 aerosol height/optical depth") (Horizontal-Spatial-Resolution ?hsr & :(neq ?hsr nil)) (Temporal-resolution ?tr) (Id ?id1))
    (test (SameOrBetter Horizontal-Spatial-Resolution ?hsr High-10-100m))
    (test (SameOrBetter Temporal-resolution ?tr High-12h-24h))
    =>
    (duplicate ?ae (Id (str-cat ?id1 "-syn")) (Parameter "1.8.16 Visible atmospheric plumes")(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::visible-atmospheric-plume-from-aerosols) " D" (call ?ae getFactId) "}"))))

; 1.8.13 Black carbon and other polluting aerosols from other aerosol measurements?
(defrule SYNERGIES::black-carbon-from-aerosols
    "identifies a synergy between polarimetric aerosol measurements and black carbon measurements, where black carbon can be measured using polarimetric aerosol measurements, and duplicates the measurement with a new ID for black carbon"
        ?ae <- (REQUIREMENTS::Measurement (Parameter "1.1.2 aerosol shape, composition, physical and chemical properties") (Polarimetry yes) (Id ?id1))
    =>
    (duplicate ?ae (Id (str-cat ?id1 "-syn")) (Parameter "1.8.13 Black carbon and other polluting aerosols")(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::black-carbon-from-aerosols) " D" (call ?ae getFactId) "}"))))

(defrule SYNERGIES::surface-composition-in-all-spectrum
    "identifies synergies between surface composition measurements taken in different spectral regions, and combines them using fuzzy logic to create a new measurement that includes both spectral regions. Equations: Temporal-resolution (fuzzy-min Temporal-resolution ?tr1 ?tr2), Spectral-sampling (fuzzy-max Spectral-sampling ?ss1 ?ss2)"
    ?VNIR <- (REQUIREMENTS::Measurement (Parameter ?p) (Spectral-region opt-VNIR+SWIR) (Temporal-resolution ?tr1&~nil) (Spectral-sampling ?ss1&~nil) (Id ?id1) (taken-by ?ins1))
    ?TIR <- (REQUIREMENTS::Measurement (Parameter ?p) (Spectral-region opt-TIR) (Temporal-resolution ?tr2&~nil) (Spectral-sampling ?ss2&~nil)  (Id ?id2) (taken-by ?ins2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (or (test (meas-group ?p 2.0.0)) (test (meas-group ?p 3.7.0)))
    =>
    (duplicate ?TIR (Spectral-region opt-VNIR+SWIR+TIR) (Temporal-resolution (fuzzy-min Temporal-resolution ?tr1 ?tr2)) (Spectral-sampling (fuzzy-max Spectral-sampling ?ss1 ?ss2)) (taken-by (str-cat ?ins1 "-syn-" ?ins2 )) (Id (str-cat ?id1 "-syn-" ?id2))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::surface-composition-in-all-spectrum) " D" (call ?TIR getFactId) " S" (call ?VNIR getFactId) "}")) )
    )

(defrule SYNERGIES::pointing-capability
    "identifies a synergy between measurements with high pointing capability taken from an orbit altitude greater than 450 km with temporal resolutions of Low-3days-1-week or Very-low-1-3-weeks, which produces a new measurement with medium temporal resolution and a synergy level of 1"
    ?m<- (REQUIREMENTS::Measurement (Parameter ?p) (Temporal-resolution ?tr1) (Pointing-capability High) (orbit-altitude# ?h&:(> ?h 450)) (Id ?id1) (taken-by ?ins1) (synergy-level# 0))
    (or (test (eq ?tr1 Low-3days-1-week)) (test (eq ?tr1 Very-low-1-3-weeks)))
    =>
    ;(printout t "pointing capability" crlf)
    (duplicate ?m (Temporal-resolution Medium-1day-3days) (synergy-level# 1) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::pointing-capability) " D" (call ?m getFactId) "}")))
    )

(defrule SYNERGIES::fire-monitoring-bands
    "identifies synergies between two measurements for fire monitoring by combining their temporal resolution and spectral sampling to produce a new measurement with higher accuracy and a wider spectral region. Equations: Fuzzy-min and fuzzy-max functions are used to combine the temporal resolution and spectral sampling values"
    ?TIR <- (REQUIREMENTS::Measurement (Id ?id1) (taken-by ?ins1) (Parameter "A2.Fire Monitoring") (Temporal-resolution ?tr1&~nil) (Spectral-sampling ?ss1&~nil)  (Accuracy ?acc&~Low) (Spectral-region opt-TIR))
    ?SWIR <- (REQUIREMENTS::Measurement (Id ?id2) (taken-by ?ins2) (Parameter "A2.Fire Monitoring") (Temporal-resolution ?tr2&~nil) (Spectral-sampling ?ss2&~nil) (Accuracy ?acc2&~Low) (Spectral-region opt-VNIR+SWIR))
    (test (neq ?ins1 ?ins2))
   =>
    (duplicate ?TIR (Accuracy High) (Spectral-region opt-VNIR+SWIR+TIR) (Temporal-resolution (fuzzy-min Temporal-resolution ?tr1 ?tr2)) (Spectral-sampling (fuzzy-max Spectral-sampling ?ss1 ?ss2))
         (taken-by (str-cat ?ins1 "-syn-" ?ins2)) (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::fire-monitoring-bands) " D" (call ?TIR getFactId) " S" (call ?SWIR getFactId) "}")))          
    )

;; *************
;; ATMOSPHERE
;; **************

;; MW sounder increases sensitivity in the troposphere of IR sounding
(defrule SYNERGIES::MW-and-IR-sounders-tropo-sensitivity
    "states that a microwave (MW) sounder increases the sensitivity in the troposphere of an infrared (IR) sounder by providing all-weather capability, and the new measurement's sensitivity is set to 'High'"
    ?IR <- (REQUIREMENTS::Measurement (Parameter "1.2.1 Atmospheric temperature fields") 
        (Spectral-region ?sr1) (sensitivity-in-low-troposphere-PBL ?sensIR) 
        (Id ?id1) (taken-by ?ins1) (synergy-level# ?s1&:(< ?s1 1)))
    ?MW <- (REQUIREMENTS::Measurement (Parameter "1.2.1 Atmospheric temperature fields") 
        (Spectral-region ?sr2) (Id ?id2) (taken-by ?ins2) (synergy-level# ?s2&:(< ?s2 1)))
    (test (integerp (str-index MW ?sr1)))
    (test (integerp (str-index opt ?sr2)))
    (test (neq ?sensIR High))
    (test (eq (str-index syn ?ins1) FALSE))
    (test (eq (str-index syn ?ins2) FALSE))
    
    =>
    (duplicate ?IR (sensitivity-in-low-troposphere-PBL High) 
        (Id (str-cat ?id1 "-syn-" ?id2)) 
        (taken-by (str-cat ?ins1 "-syn-" ?ins2 ))
        (synergy-level# (+ (max ?s1 ?s2) 1)) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::MW-and-IR-sounders-tropo-sensitivity) " D" (call ?IR getFactId) " S" (call ?MW getFactId) "}"))
        )
    )



;; all weather mw measurements complement ir measurements of the same parameter
(defrule SYNERGIES::add-all-weather-capability
    "identifies synergies between measurements of the same parameter, where one has all-weather capability and the other does not, allowing for assimilation of both to obtain an all-weather capability measurement"
    (declare (no-loop TRUE) (salience -50))
    ?no <- (REQUIREMENTS::Measurement (Parameter ?p) (All-weather no) (Id ?id1) (taken-by ?ins1) (synergy-level# ?s1&:(< ?s1 3)))
    ?sub <- (REQUIREMENTS::Measurement (Parameter ?p) (All-weather yes) (Id ?id2) (taken-by ?ins2) (synergy-level# ?s2&:(< ?s2 1)))
    ;(not (REQUIREMENTS::Measurement (Parameter ?p) (All-weather yes) (Id ?id3&:(eq ?id3 (str-cat ?id1 "-syn-" ?id2))) ))
    (not (REASONING::stop-improving (Measurement ?p)))
    ;(test (eq (str-index syn ?ins1) FALSE))
    ;(test (eq (str-index syn ?ins2) FALSE))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    =>
    ; (printout t "worth-improving " (worth-improving-measurement ?p) crlf)
    (duplicate ?no (All-weather yes) (Id (str-cat ?id1 "-syn-" ?id2))
        (taken-by (str-cat ?ins1 "-syn-" ?ins2 )) (synergy-level# (+ (max ?s1 ?s2) 1))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::add-all-weather-capability) " D" (call ?no getFactId) " S" (call ?sub getFactId) "}")))
    )

(defrule SYNERGIES::add-cloud-mask
    "identifies a synergy between an imager and another instrument that does not provide cloud mask information, where the imager can be used to obtain cloud-cleared images of the second instrument, and it updates the fact history and synergy level of the measurement while inserting a new measurement with the added cloud mask information"
    (declare (no-loop TRUE) (salience 10))
    ?no <- (REQUIREMENTS::Measurement (Parameter ?p) (cloud-cleared no) (Id ?id1) (taken-by ?ins1) (synergy-level# ?s1&:(< ?s1 2)) (factHistory ?fh))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "1.5.4 cloud mask") (Id ?id2) (taken-by ?ins2) (synergy-level# ?s2&:(< ?s2 1)))
    ?sub2 <- (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    
    =>
    (modify ?no (cloud-cleared yes) (Id (str-cat ?id1 "-mask-" ?id2)) (taken-by (str-cat ?ins1 "-mask-" ?ins2 )) (synergy-level# (+ 1 (max ?s1 ?s2))) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::add-cloud-mask) " " ?fh " S" (call ?sub getFactId) "}")))
    (assert (SYNERGIES::cross-registered (measurements (insert$ $?m (+ 1 (length$ $?m)) (str-cat ?id1 "-mask-" ?id2 ))) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::add-cloud-mask) " A" (call ?no getFactId) " A" (call ?sub getFactId) " A" (call ?sub2 getFactId) "}")) ))
    )

;; mmw trace gases measurements complement ir measurements of the same parameter with enhanced sensitivity in cirrus
(defrule SYNERGIES::add-sensitivity-in-cirrus-from-mmw-measurement
    "identifies synergies between mmw trace gases measurements and ir measurements of the same parameter to enhance sensitivity in cirrus, by assimilating them and creating an all-weather capability measurement"
    (declare (no-loop TRUE) (salience -50))
    ?no <- (REQUIREMENTS::Measurement (Parameter ?p) (sensitivity-in-cirrus ?s&~High) (Id ?id1) (taken-by ?ins1) (synergy-level# ?s1&:(< ?s1 2)))
    ?sub <- (REQUIREMENTS::Measurement (Parameter ?p) (sensitivity-in-cirrus High) (Id ?id2) (taken-by ?ins2) (synergy-level# ?s2&:(< ?s2 1)))
    (not (REASONING::stop-improving (Measurement ?p)))
    ;(test (eq (str-index syn ?ins1) FALSE))
    ;(test (eq (str-index syn ?ins2) FALSE))
    ;(SYNERGIES::cross-registered (measurements $?m))
    ;(test (member$ ?id1 $?m))
    ;(test (member$ ?id2 $?m))
    
    =>
    ; (printout t "worth-improving " (worth-improving-measurement ?p) crlf)
    (duplicate ?no (sensitivity-in-cirrus High) (Id (str-cat ?id1 "-syn-" ?id2))
        (taken-by (str-cat ?ins1 "-syn-" ?ins2 )) (synergy-level# (+ 1 (max ?s1 ?s2))) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::add-sensitivity-in-cirrus-from-mmw-measurement) " D" (call ?no getFactId) " S" (call ?sub getFactId) "}")))
    )

;; mmw trace gases measurements complement ir measurements of the same parameter with enhanced sensitivity in cirrus
(defrule SYNERGIES::add-sensitivity-in-convective-clouds
    "identifies synergies between two measurements of the same parameter, where one has high sensitivity over convective clouds and the other does not, and assimilates them to produce a better measurement with sensitivity in convective clouds"
    (declare (no-loop TRUE) (salience -50))
    ?no <- (REQUIREMENTS::Measurement (Parameter ?p) (sensitivity-in-convective-clouds ?s&~High) (Id ?id1) (taken-by ?ins1) (synergy-level# ?s1&:(< ?s1 2)))
    ?sub <- (REQUIREMENTS::Measurement (Parameter ?p) (sensitivity-in-convective-clouds High) (Id ?id2) (taken-by ?ins2) (synergy-level# ?s2&:(< ?s2 1)))
    (not (REASONING::stop-improving (Measurement ?p)))
    ;(test (eq (str-index syn ?ins1) FALSE))
    ;(test (eq (str-index syn ?ins2) FALSE))
    ;(SYNERGIES::cross-registered (measurements $?m))
    ;(test (member$ ?id1 $?m))
    ;(test (member$ ?id2 $?m))
    =>
    ; (printout t "worth-improving " (worth-improving-measurement ?p) crlf)
    (duplicate ?no (sensitivity-in-convective-clouds High) (Id (str-cat ?id1 "-syn-" ?id2))
        (taken-by (str-cat ?ins1 "-syn-" ?ins2 )) (synergy-level# (+ 1 (max ?s1 ?s2))) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::add-sensitivity-in-convective-clouds) " D" (call ?no getFactId) " S" (call ?sub getFactId) "}")))
    )

; limb sounders improve nadir sounders and vice versa because synergy between column and profile measurements independent
(defrule SYNERGIES::column-vs-profile-chemistry-measurements
    "identifies a synergy between column and profile measurements in space mission design, where the addition of a profile measurement to a column measurement improves both measurements independently due to the two independent measurements of the total column"
    ?col <- (REQUIREMENTS::Measurement (Parameter ?p) (Vertical-Spatial-Resolution nil)
     (Id ?id1) (taken-by ?ins1) (Accuracy ?acc1&~nil) (synergy-level# ?s1&:(< ?s1 2)))
    ?sub <- (REQUIREMENTS::Measurement (Parameter ?p) (Vertical-Spatial-Resolution ?vsr&~nil)
     (Id ?id2) (taken-by ?ins2) (Accuracy ?acc2) (synergy-level# ?s2&:(< ?s2 1)))
    ;(not (REASONING::stop-improving (Measurement ?p)))
    (test (eq (str-index syn ?ins1) FALSE))
    (test (eq (str-index syn ?ins2) FALSE))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    =>
    (printout t "--> SYNERGY column vs profile, accuracy before / after: " ?acc1 " | " (eval (Improve Accuracy ?acc1)) crlf)
    (duplicate ?col (Accuracy (eval (Improve Accuracy ?acc1))) (Id (str-cat ?id1 "-syn-" ?id2))
        (taken-by (str-cat ?ins1 "-syn-" ?ins2 )) (Vertical-Spatial-Resolution ?vsr) (synergy-level# (+ 1 (max ?s1 ?s2)))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::column-vs-profile-chemistry-measurements) " D" (call ?col getFactId) " S" (call ?sub getFactId) "}")))
    
    )

; tropospheric vs stratospheric chemistry measurements
(defrule SYNERGIES::tropo-vs-strato-chemistry-measurements
    "identifies synergies between chemistry measurements in the troposphere and stratosphere by checking for high sensitivity in both regions and creates new measurements with high sensitivity in both regions, with synergy levels increased by one"
    (declare (no-loop TRUE) (salience -50))
    ?tro <- (REQUIREMENTS::Measurement (Parameter ?p) (sensitivity-in-low-troposphere-PBL High) (synergy-level# ?s1&:(< ?s1 2))
    (sensitivity-in-upper-troposphere-and-stratosphere ?sr&~High) (Id ?id1) (taken-by ?ins1) (Accuracy ?acc1&~nil))
    ?str <- (REQUIREMENTS::Measurement (Parameter ?p) (sensitivity-in-low-troposphere-PBL ?tr&~High) (synergy-level# ?s2&:(< ?s2 2))
     (sensitivity-in-upper-troposphere-and-stratosphere High) (Id ?id2) (taken-by ?ins2) (Accuracy ?acc2))
    ;(test (eq (str-index syn ?ins1) FALSE))
    ;(test (eq (str-index syn ?ins2) FALSE))
    ;(not (REASONING::stop-improving (Measurement ?p)))
    ;(SYNERGIES::cross-registered (measurements $?m))
    ;(test (member$ ?id1 $?m))
    ;(test (member$ ?id2 $?m))
    =>
    ; (printout t "worth-improving " (worth-improving-measurement ?p) crlf)
    (duplicate ?tro (Id (str-cat ?id1 "-syn-" ?id2)) (sensitivity-in-upper-troposphere-and-stratosphere High)
        (taken-by (str-cat ?ins1 "-syn-" ?ins2 )) (synergy-level# (+ 1 (max ?s1 ?s2)))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::tropo-vs-strato-chemistry-measurements) " D" (call ?tro getFactId) " S" (call ?str getFactId) "}")))
    (duplicate ?str (Id (str-cat ?id1 "-syn-" ?id2)) (sensitivity-in-low-troposphere-PBL High)
        (taken-by (str-cat ?ins1 "-syn-" ?ins2 )) (synergy-level# (+ 1 (max ?s1 ?s2)))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::tropo-vs-strato-chemistry-measurements) " D" (call ?str getFactId) " S" (call ?tro getFactId) "}")))
    )

; rain rate
(defrule SYNERGIES::mmw-sounders-rain-rates-hurricanes
    "states if there is a cloud liquid water and precipitation measurement and the instrument has H2O bands in the MMW then it can measure rain rate, hurricanes, etc"
    ?cl<-  (REQUIREMENTS::Measurement (Parameter "1.7.1 Cloud liquid water and precipitation rate")
        (taken-by ?ins) )
    ?sub <-(CAPABILITIES::Manifested-instrument (Name ?ins) (Spectral-region MW-submm))
    (not (REQUIREMENTS::Measurement (Parameter "1.7.3 Rain rate, tropical storms, and hurricanes")
            (taken-by ?ins)))
    =>
    ;(printout t "SYNERGIES::mmw-sounders-rain-rates-hurricanes" crlf)
    (duplicate ?cl (Parameter "1.7.3 Rain rate, tropical storms, and hurricanes")(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::mmw-sounders-rain-rates-hurricanes) " D" (call ?cl getFactId) " S" (call ?sub getFactId) "}")))
    )

; sensitivity over oceans
(defrule SYNERGIES::sensitivity-over-oceans
    "states if we have two measurements and one has good sensitivity over oceans we can combine it with another one with lower sensitivity to create a new data product"
    
    ?no <- (REQUIREMENTS::Measurement (Parameter ?p) (sensitivity-over-oceans no)
    (Id ?id1) (taken-by ?ins1) (Accuracy ?acc1&~nil) (synergy-level# ?s1&:(< ?s1 3)))
    ?sub <-(REQUIREMENTS::Measurement (Parameter ?p) (sensitivity-over-oceans High)
     (Id ?id2) (taken-by ?ins2) (Accuracy ?acc2) (synergy-level# ?s2&:(< ?s2 1)))
    ;(test (eq (str-index syn ?ins1) FALSE))
    ;(test (eq (str-index syn ?ins2) FALSE))
    ;(not (REASONING::stop-improving (Measurement ?p)))
    =>
    ; (printout t "worth-improving " (worth-improving-measurement ?p) crlf)
    (duplicate ?no (Id (str-cat ?id1 "-syn-" ?id2)) (sensitivity-over-oceans High)
        (taken-by (str-cat ?ins1 "-syn-" ?ins2 )) (synergy-level# (+ 1 (max ?s2 ?s1)))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::sensitivity-over-oceans) " D" (call ?no getFactId) " S" (call ?sub getFactId) "}")))
    
    )

; num soundings per day
(defrule count-num-soundings-per-day
    "computes number of soundings per day from number of satellites carrying GPS receivers, based on paper Research on the Number and Distribution of GPS Occultation Events for Orbit Selection for Global/Regional Observation, RAST 2007"

    ?m <- (REQUIREMENTS::Measurement (Parameter "1.3.3 GPS radio occultation") (taken-by ?tk)
        (num-soundings-per-day# nil) (num-of-planes# ?np&~nil) (num-of-sats-per-plane# ?ns&~nil) )
    =>
    (bind ?ns (* 450 (* ?ns ?np))); 450 soundings/day per satellite
    (modify ?m (num-soundings-per-day# ?ns))
    ;(printout t "nsoundings of " ?tk " = " ?ns crlf)
    )

(defrule count-num-soundings-per-day-when-nil
    "computes number of soundings per day from number of satellites carrying GPS receivers, based on paper Research on the Number and Distribution of GPS
Occultation Events for Orbit Selection for Global/Regional Observation, RAST 2007"

   ?m <-  (REQUIREMENTS::Measurement (Parameter "1.3.3 GPS radio occultation") (taken-by ?tk)
        (num-soundings-per-day# nil) (num-of-planes# nil) (num-of-sats-per-plane# nil) )
    =>
    (bind ?ns 450); 450 soundings/day per satellite
    (modify ?m (num-soundings-per-day# ?ns))
    ;(printout t "nsoundings of " ?tk " = " ?ns crlf)
    )

(defrule SYNERGIES::num-soundings-per-day-add
    "computes number of soundings per day from number of satellites carrying GPS receivers, based on paper Research on the Number and Distribution of GPS Occultation Events for Orbit Selection for Global/Regional Observation, RAST 2007"
    
    ?m1 <- (REQUIREMENTS::Measurement (Parameter "1.3.3 GPS radio occultation") (num-soundings-per-day# ?ns1&~nil) (taken-by ?tk1) (factHistory ?fh1))
    ?m2 <- (REQUIREMENTS::Measurement (Parameter "1.3.3 GPS radio occultation") (num-soundings-per-day# ?ns2&~nil) (taken-by ?tk2) (factHistory ?fh2))
    (test (neq ?m1 ?m2))
    => 
    (retract ?m1)
    (modify ?m2 (num-soundings-per-day# (+ ?ns1 ?ns2)) (taken-by (str-cat ?tk1 ?tk2))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::num-soundings-per-day-add) " " ?fh2 "}")))
    ;(printout t "nsoundings of " ?tk " = " (+ ?ns1 ?ns2) crlf)
    )

;; SMAP specific rules
;(defrule SYNERGIES::SMAP-spatial-disaggregation "A frequent coarse spatial resolution measurement can be combined with a sparse high spatial resolution measurement to produce a frequent high spatial resolution measurement with average accuracy"
;    ?m1 <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture") (Horizontal-Spatial-Resolution ?hsr1&~nil) (Accuracy ?a1&~nil) (Id ?id1) (taken-by ?ins1))
;    ?m2 <- (REQUIREMENTS::Measurement (Parameter "2.3.2 soil moisture") (Horizontal-Spatial-Resolution ?hsr2&~nil) (Accuracy ?a2&~nil) (Id ?id2) (taken-by ?ins2))
;    (SYNERGIES::cross-registered (measurements $?m))
;    (test (member$ ?id1 $?m))
;    (test (member$ ?id2 $?m))
;    (not (REASONING::stop-improving (Measurement ?p)))
;    (test (eq (str-index disaggregated ?ins1) FALSE))
;    (test (eq (str-index disaggregated ?ins2) FALSE))
;    (test (neq ?id1 ?id2));;
;;
;	=>
;
 ;   (duplicate ?m1 (Horizontal-Spatial-Resolution (eval (fuzzy-max Horizontal-Spatial-Resolution ?hsr1 ?hsr2))) 
  ;          (Accuracy (eval (fuzzy-max Accuracy ?a1 ?a2))) 
   ;         (Id (str-cat ?id1 "-disaggregated" ?id2))
    ;        (taken-by (str-cat ?ins1 "-" ?ins2 "-disaggregated")));; fuzzy-max in accuracy is OK because joint product does provide 4% accuracy
;);

;; *************************
;; SYNERGIES IN ERROR BUDGETS
;; *************************

; ALTIMETRY


;; ***********************
;; RADIANCE
;; ***********************
;; clouds and radiation budget

(defrule SYNERGIES::clouds-and-radiation2
    "identifies synergies between measurements of spectrally resolved SW radiance and cloud amount/distribution to create a new measurement of 'Clouds and radiation'"
    ?sub1<- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (Name ?n1&~ACRIM) )
    ?sub2<- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (Name ?n2&~?n1&~ACRIM) )
    ?sub3<- (REQUIREMENTS::Measurement (Parameter "1.9.3 Spectrally resolved SW radiance -0.3-2um-") (Id ?id1) (taken-by ?ins1)) 
    ?clouds <- (REQUIREMENTS::Measurement (Parameter "1.5.3 Cloud amount/distribution -horizontal and vertical-") (Id ?id2) (taken-by ?ins2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (test (eq (str-index syn ?ins1) FALSE))
    (test (eq (str-index syn ?ins2) FALSE))
 
    (not (REQUIREMENTS::Measurement (Parameter "A4.Clouds and radiation") (num-of-indep-samples# 2)))
    =>
    (duplicate ?clouds (Parameter "A4.Clouds and radiation") (num-of-indep-samples# 2)
        (Id (str-cat ?id1 "-syn-" ?id2))  (taken-by (str-cat ?ins1 "-syn-" ?ins2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::clouds-and-radiation2) " D" (call ?clouds getFactId) " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) " S" (call ?sub3 getFactId) "}")))
    ;(printout t CERES2 crlf)
    ;(assert (REQUIREMENTS::Measurement (Parameter "A4.Clouds and radiation") (num-of-indep-samples# 2)))
    )

(defrule SYNERGIES::clouds-and-radiation3
    "identifies synergies between three Earth radiation budget radiometers and cloud amount/distribution measurements to produce a new measurement for the Clouds and radiation parameter,"
    ?sub1<- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (Name ?n1&~ACRIM))
    ?sub2<- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (Name ?n2&~?n1&~ACRIM))
    ?sub3<- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (Name ?n3&~?n2&~?n1&~ACRIM))
    ?sub4<- (REQUIREMENTS::Measurement (Parameter "1.9.3 Spectrally resolved SW radiance -0.3-2um-") (Id ?id1) (taken-by ?ins1)) 
    ?clouds <- (REQUIREMENTS::Measurement (Parameter "1.5.3 Cloud amount/distribution -horizontal and vertical-") (Id ?id2) (taken-by ?ins2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (test (eq (str-index syn ?ins1) FALSE))
    (test (eq (str-index syn ?ins2) FALSE))
    (not (REQUIREMENTS::Measurement (Parameter "A4.Clouds and radiation") (num-of-indep-samples# 3)))
    =>
    ;(printout t clouds-and-radiation3 ?n1 " " ?n2 " " ?n3 crlf)
    (duplicate ?clouds (Parameter "A4.Clouds and radiation") (num-of-indep-samples# 3)
        (Id (str-cat ?id1 "-syn-" ?id2))  (taken-by (str-cat ?ins1 "-syn-" ?ins2 "-syn" ?n1 "-syn" ?n2 "-syn" ?n3)) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::clouds-and-radiation3) " D" (call ?clouds getFactId) " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) " S" (call ?sub3 getFactId) " S" (call ?sub4 getFactId) "}")))
    ;(assert (REQUIREMENTS::Measurement (Parameter "A4.Clouds and radiation") (num-of-indep-samples# 3)))
    )

(defrule SYNERGIES::CERES-sampling-multiple-angles-SW 
    "identifies the need to have one instrument in a cross-track scanning configuration and another in azimuth scanning configuration to obtain good spatial sampling and to sample all possible angles respectively, and modifies the required measurement to have an rms-variable-angular-sampling# of 1.2, averaged over 30 days and calculated using the equation in Wielicki et al 1995"
    (declare (no-loop TRUE))
    ?sub1 <- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (scanning cross-track) (Name ?n1))
    ?sub2 <- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (scanning biaxial) (Name ?n2&:(neq ?n1 ?n2)))
    ?m <- (REQUIREMENTS::Measurement (Parameter "1.9.3 Spectrally resolved SW radiance -0.3-2um-") (rms-variable-angular-sampling# ?ang) (factHistory ?fh))
    (test (eq (numberp ?ang) FALSE));; essentially nil
    =>
    (modify ?m (rms-variable-angular-sampling# 1.2) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::CERES-sampling-multiple-angles-SW) " " ?fh " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) "}"))) ;; 1sigma, in W/m2 averaged over 30 days, Wielicki et al 1995
    )

(defrule SYNERGIES::CERES-sampling-multiple-angles-LW
    "identifies a synergy between two instruments used for Earth radiation budget radiometry, where one instrument is cross-track scanning and the other is azimuth scanning. The rule modifies a measurement to improve the sampling by setting a variable angular sampling to 1.2"
    (declare (no-loop TRUE))
    ?sub1 <- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (scanning cross-track) (Name ?n1))
    ?sub2 <- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (scanning biaxial) (Name ?n2&:(neq ?n1 ?n2)))
    ?m <- (REQUIREMENTS::Measurement (Parameter "1.9.2 Spectrally resolved IR radiance -200-2000cm-1-") (rms-variable-angular-sampling# ?ang) (factHistory ?fh))
    (test (eq (numberp ?ang) FALSE));; essentially nil
    =>
    (modify ?m (rms-variable-angular-sampling# 1.2) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::CERES-sampling-multiple-angles-LW) " " ?fh " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) "}"))) ;; 1sigma, in W/m2 averaged over 30 days, Wielicki et al 1995
    )


(defrule SYNERGIES::CERES-sampling-single-angle-SW
    (declare (no-loop TRUE))
    ?sub <- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (scanning cross-track) (Name ?n1))
    (not (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (scanning biaxial) ))
    ?m <- (REQUIREMENTS::Measurement (Parameter "1.9.3 Spectrally resolved SW radiance -0.3-2um-") (rms-variable-angular-sampling# ?ang) (factHistory ?fh))
    
    (test (eq (numberp ?ang) FALSE));; essentially nil
    =>
    (modify ?m (rms-variable-angular-sampling# 4.8) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::CERES-sampling-single-angle-SW) " " ?fh " S" (call ?sub getFactId) "}"))) ;; 1sigma, in W/m2 averaged over 30 days, Wielicki et al 1995
    )

(defrule SYNERGIES::CERES-sampling-single-angle-LW
    (declare (no-loop TRUE))
    ?sub <- (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (scanning cross-track) (Name ?n1))
    (not (CAPABILITIES::Manifested-instrument (Intent "Earth radiation budget radiometers") (scanning biaxial) ))
    ?m <- (REQUIREMENTS::Measurement (Parameter "1.9.2 Spectrally resolved IR radiance -200-2000cm-1-") (rms-variable-angular-sampling# ?ang) (factHistory ?fh))
    (test (eq (numberp ?ang) FALSE));; essentially nil
    =>
    (modify ?m (rms-variable-angular-sampling# 4.8)(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::CERES-sampling-single-angle-LW) " " ?fh " S" (call ?sub getFactId) "}"))) ;; 1sigma, in W/m2 averaged over 30 days, Wielicki et al 1995
    )

(defrule SYNERGIES::CERES-sampling-time-SW2
    (declare (no-loop TRUE) (salience -3))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "A4.Clouds and radiation") (num-of-indep-samples# ?n&2))
    ?m <- (REQUIREMENTS::Measurement (Parameter "1.9.3 Spectrally resolved SW radiance -0.3-2um-") (rms-variable-time-sampling# ?tim) (factHistory ?fh))
    (test (eq (numberp ?tim) FALSE));; essentially nil
    =>
    (if (eq ?n 1) then (bind ?x 10.45) elif (eq ?n 2) then (bind ?x 2.3) elif (eq ?n 3) then (bind ?x 0.47) else (bind ?x 15.0))
    (modify ?m (rms-variable-time-sampling# ?x)(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::CERES-sampling-time-SW2) " " ?fh " S" (call ?sub getFactId) "}"))) ;; 1sigma, in W/m2 averaged over 30 days, Wielicki et al 1995
    )

(defrule SYNERGIES::CERES-sampling-time-LW2
    "identifies a synergy between the CERES measurement error and the number of independent samples, reducing error as the number of samples increases, as described in Wielicki et al. 1995"
    (declare (no-loop TRUE) (salience -3))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "A4.Clouds and radiation") (num-of-indep-samples# ?n&2))
    ?m <- (REQUIREMENTS::Measurement (Parameter "1.9.2 Spectrally resolved IR radiance -200-2000cm-1-") (rms-variable-time-sampling# ?tim) (factHistory ?fh))
    (test (eq (numberp ?tim) FALdSE));; essentially nil
    =>
    (if (eq ?n 1) then (bind ?x 10.45) elif (eq ?n 2) then (bind ?x 2.3) elif (eq ?n 3) then (bind ?x 0.47) else (bind ?x 15.0))
    (modify ?m (rms-variable-time-sampling# ?x)(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::CERES-sampling-time-LW2) " " ?fh " S" (call ?sub getFactId) "}"))) ;; 1sigma, in W/m2 averaged over 30 days, Wielicki et al 1995
    )

(defrule SYNERGIES::CERES-sampling-time-SW3
    "states, for the CERES mission, it is required to have one instrument in a cross-track scanning configuration to get good spatial sampling and another one in azimuth scanning configuration in order to sample all possible angles"
    (declare (no-loop TRUE) (salience -3))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "A4.Clouds and radiation") (num-of-indep-samples# ?n&3))
    ?m <- (REQUIREMENTS::Measurement (Parameter "1.9.3 Spectrally resolved SW radiance -0.3-2um-") (rms-variable-time-sampling# ?tim) (factHistory ?fh))
    (test (eq (numberp ?tim) FALSE));; essentially nil
    =>
    (if (eq ?n 1) then (bind ?x 10.45) elif (eq ?n 2) then (bind ?x 2.3) elif (eq ?n 3) then (bind ?x 0.47) else (bind ?x 15.0))
    (modify ?m (rms-variable-time-sampling# ?x)(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::CERES-sampling-time-SW3) " " ?fh " S" (call ?sub getFactId) "}"))) ;; 1sigma, in W/m2 averaged over 30 days, Wielicki et al 1995
    )

(defrule SYNERGIES::CERES-sampling-time-LW3
    "states that for CERES, error due to sampling time decreases with the number of independent samples, and assigns a value to the root mean square (RMS) error of the variable time sampling, based on the number of independent samples as shown in the equation: $\begin{cases} \text{if } n=1, \text{then } x=10.45\ \text{if } n=2, \text{then } x=2.3\ \text{if } n=3, \text{then } x=0.47\ \text{otherwise, } x=15.0 \end{cases}$ where $n$ is the number of independent samples and $x$ is the assigned value to the RMS error of the variable time sampling in units of W/m2 averaged over 30 days"
    (declare (no-loop TRUE) (salience -3))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "A4.Clouds and radiation") (num-of-indep-samples# ?n&3))
    ?m <- (REQUIREMENTS::Measurement (Parameter "1.9.2 Spectrally resolved IR radiance -200-2000cm-1-") (rms-variable-time-sampling# ?tim) (factHistory ?fh))
    (test (eq (numberp ?tim) FALSE));; essentially nil
    =>
    (if (eq ?n 1) then (bind ?x 10.45) elif (eq ?n 2) then (bind ?x 2.3) elif (eq ?n 3) then (bind ?x 0.47) else (bind ?x 15.0))
    (modify ?m (rms-variable-time-sampling# ?x) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::CERES-sampling-time-LW3) " " ?fh " S" (call ?sub getFactId) "}"))) ;; 1sigma, in W/m2 averaged over 30 days, Wielicki et al 1995
    )

(defrule SYNERGIES::radiation-budget-err-total-SW
    "computes the total root mean square error for a radiation budget mission by summing the instrument error, angular sampling error, and time sampling error using the equation \sqrt{(\text{angular sampling error})^2 + (\text{instrument error})^2 + (\text{time sampling error})^2}. Equations: \sqrt{(\text{angular sampling error})^2 + (\text{instrument error})^2 + (\text{time sampling error})^2}. See Wielicki et al 95 about CERES for more info"
    (declare (no-loop TRUE) (salience -5))
    ?meas <- (REQUIREMENTS::Measurement (Parameter "1.9.3 Spectrally resolved SW radiance -0.3-2um-") (rms-variable-angular-sampling# ?ang)
         (rms-variable-time-sampling# ?tim) (rms-system-instrument# ?ins) (rms-total# 100.0) (factHistory ?fh))
    
    =>
    (if (eq ?ins nil) then (bind ?ins 0))
    (if (eq ?ang nil) then (bind ?ang 0))
    (if (eq ?tim nil) then (bind ?tim 0))
    (bind ?rms-total (sqrt (+ (** ?ang 2) (** ?ins 2) (** ?tim 2) )))
    
    (modify ?meas (rms-total# ?rms-total) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::radiation-budget-err-total-SW) " " ?fh "}")))
    )

(defrule SYNERGIES::radiation-budget-err-total-LW
    "calculates the total root mean square error for a radiation budget mission, taking into account instrument error, angular sampling error, and time sampling error using the equation \sqrt{(\text{angular sampling error})^2+(\text{instrument error})^2+(\text{time sampling error})^2}.. See Wielicki et al 95 about CERES for more info"
    (declare (no-loop TRUE) (salience -5))
    ?meas <- (REQUIREMENTS::Measurement (Parameter "1.9.2 Spectrally resolved IR radiance -200-2000cm-1-") (rms-variable-angular-sampling# ?ang)
         (rms-variable-time-sampling# ?tim) (rms-system-instrument# ?ins) (rms-total# 100.0) (factHistory ?fh))
    
    =>
     (if (eq ?ins nil) then (bind ?ins 0))
    (if (eq ?ang nil) then (bind ?ang 0))
    (if (eq ?tim nil) then (bind ?tim 0))
    (bind ?rms-total (sqrt (+ (** ?ang 2) (** ?ins 2) (** ?tim 2) )))
    (modify ?meas (rms-total# ?rms-total) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::radiation-budget-err-total-LW) " " ?fh "}")))
    )


;; ****************
;; Sea surface winds 
;; ****************

; 
(defrule SYNERGIES::sea-surface-winds-combining-SAR-and-scatterometer
    "combines sea surface wind measurements from SAR and scatterometers to increase sensitivity, with the resulting sensitivity determined by the equation RMS = 0.75 * min(ERR1, ERR2), as described in Monaldo et al, TGRS 2004 Vol 42, Iss 2."
    (declare (no-loop TRUE))
    ?m1 <- (REQUIREMENTS::Measurement (Parameter "3.4.1 Ocean surface wind speed") (taken-by ?sar) (rms-variable-measurement# ?err1&~nil))
    ?m2 <- (REQUIREMENTS::Measurement (Parameter "3.4.1 Ocean surface wind speed") (taken-by ?scat&:(neq ?scat ?sar)) (rms-variable-measurement# ?err2&~nil) (factHistory ?fh))
    ?sub1 <- (CAPABILITIES::Manifested-instrument (Intent "Imaging MW radars -SAR-") (Name ?sar))
    ?sub2 <- (CAPABILITIES::Manifested-instrument (Intent "Radar scatterometer") (Name ?scat))
    (SYNERGIES::cross-registered-instruments (instruments $?ins) (degree-of-cross-registration spacecraft))
    (test (member$ ?sar $?ins))
    (test (member$ ?scat $?ins))
    =>
    (modify ?m2 (rms-variable-measurement# ?sens (* 0.75 (min ?err1 ?err2)))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::sea-surface-winds-combining-SAR-and-scatterometer) " " ?fh " S" (call ?m1 getFactId) " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) "}")))
	)

 
(defrule SYNERGIES::sea-surface-winds-with-high-winds
    "identifies the sensitivity of C-band scatterometry over Ka/Ku at high winds, assigning a high sensitivity to C-band scatterometry if its spectral region is MW-C, and low otherwise, using the equation (if (eq ?sp MW-C) then (bind ?sens High) else (bind ?sens Low)). See Decadal Survey report on XOVWM mission"
    (declare (no-loop TRUE))
    ;; sensitivity-in-high-winds high if C-band scatterometer
    ?m <- (REQUIREMENTS::Measurement (Parameter "3.4.1 Ocean surface wind speed") (taken-by ?ins) (sensitivity-in-high-winds nil)(factHistory ?fh))
    ?sub <- (CAPABILITIES::Manifested-instrument (Intent "Radar scatterometer") (Name ?ins) (Spectral-region ?sp))
    =>
    (if (eq ?sp MW-C) then (bind ?sens High) else (bind ?sens Low))
    (modify ?m (sensitivity-in-high-winds ?sens)(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::sea-surface-winds-with-high-winds) " " ?fh " S" (call ?sub getFactId) "}")))
    )

;; *********
;; Land use, land cover, vegetation
;; **********


            
(defrule SYNERGIES::add-multi-angular-capability
    "identifies the synergies that exist when a multi-angular radiometer is combined with another imager, and creates a common measurement that combines the characteristics of the two"
    (declare (no-loop TRUE) (salience 5))
    
    ?no <- (REQUIREMENTS::Measurement (Parameter ?p) (taken-by ?ins1) (Id ?id1) (ThreeD ?td1 &~ Full-3D) (synergy-level# ?s1&:(< ?s1 1)))
    ?sub <- (REQUIREMENTS::Measurement (Parameter ?p) (taken-by ?ins2) (Id ?id2) (ThreeD ?td2 &~ No-3D &~ N-A &~ nil) (synergy-level# ?s2&:(< ?s2 1)))
    (or (test (meas-group ?p 1.0.0)) (test (meas-group ?p 2.0.0)))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (test (> (SameOrBetter ThreeD ?td2 ?td1) 0))
    
    =>
     (duplicate ?no (ThreeD ?td2) (Id (str-cat ?id1 "-multiang-" ?id2))  (taken-by (str-cat ?ins1 "-multiang-" ?ins2 )) (synergy-level# (+ 1 (max ?s1 ?s2)))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::add-multi-angular-capability) " D" (call ?no getFactId) " S" (call ?sub getFactId) "}")))
    )

(defrule SYNERGIES::HSR-TR-ThreeD-combination-scheme
    "identifies a synergy between a MODIS-like instrument, an ASTER-like instrument, and a MISR-like instrument, by combining measurements with specific parameters and accuracy levels, and cross-registering them to produce a new measurement with improved horizontal spatial resolution and full 3D information"
    (declare (no-loop TRUE) (salience 10))
    
    ?MODIS <- (REQUIREMENTS::Measurement (Parameter ?p) (Accuracy High) (Horizontal-Spatial-Resolution Medium-100m-1km) (Temporal-resolution Medium-1day-3days) (taken-by ?ins1) (Id ?id1) (ThreeD ?td1 &~ Full-3D))
    ?ASTER <- (REQUIREMENTS::Measurement (Parameter ?p) (Accuracy High) (Horizontal-Spatial-Resolution High-10-100m) (Temporal-resolution Very-low-1-3-weeks) (taken-by ?ins2) (Id ?id2) (ThreeD ?td2 &~ No-3D &~ N-A &~ nil))
    ?MISR <- (REQUIREMENTS::Measurement (Parameter ?p) (Accuracy High) (Horizontal-Spatial-Resolution Medium-100m-1km) (Temporal-resolution Very-low-1-3-weeks) (taken-by ?ins3) (Id ?id3) (ThreeD Full-3D))
    (or (test (meas-group ?p 1.0.0)) (test (meas-group ?p 2.0.0)))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (test (member$ ?id3 $?m))
    =>
    ;(printout t HSR-TR-ThreeD-combination-scheme " " (str-cat ?ins1 "-disaggr-" ?ins2 "-multiang-" ?ins3) crlf)
     (duplicate ?MODIS (ThreeD Full-3D) (Horizontal-Spatial-Resolution High-10-100m)  (Id (str-cat ?id1 "-disagg-" ?id2 "-multiang-" ?id3))  (taken-by (str-cat ?ins1 "-disaggr-" ?ins2 "-multiang-" ?ins3))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::HSR-TR-ThreeD-combination-scheme) " D" (call ?MODIS getFactId) " S" (call ?ASTER getFactId) " S" (call ?MISR getFactId) "}")))
    )

(defrule SYNERGIES::temperature-sounding-suite
    "identifies the requirements for temperature sounding, which requires a hyperspectral IR sounder, a MW sounder with T channels, and a cloud mask, and involves measurements of atmospheric temperature fields with certain spectral-sampling, vertical-spatial-resolution, and temporal-resolution, as well as high sensitivity and accuracy over oceans, and produces a new measurement with a higher synergy-level"
    (declare (no-loop TRUE) (salience 5))
    
    ?AIRS-MODIS <- (REQUIREMENTS::Measurement (Parameter "1.2.1 Atmospheric temperature fields") (cloud-cleared yes) (Vertical-Spatial-Resolution ?vsr1&~nil&~None) 
        (Spectral-sampling Hyperspectral-100-channels-or-more) (Temporal-resolution ?tr1) (taken-by ?ins1) (Id ?id1) (All-weather no) (synergy-level# ?s1&:(< ?s1 2)))
    ?AMSU <- (REQUIREMENTS::Measurement (Parameter "1.2.1 Atmospheric temperature fields") (sensitivity-over-oceans High) (Accuracy High) (Spectral-sampling ?ss) (All-weather yes) (taken-by ?ins2) (Id ?id2) (synergy-level# ?s2&:(< ?s2 1)))
    (test (>= (SameOrBetter Spectral-sampling ?ss Multispectral-10-100-channels) 0))
    ;(SYNERGIES::cross-registered (measurements $?m))
    ;(test (member$ ?id1 $?m))
    ;(test (member$ ?id2 $?m))
    =>
    ;(printout t temperature-sounding-suite crlf)
     (duplicate ?AIRS-MODIS (All-weather yes) (sensitivity-over-oceans High) (Id (str-cat ?id1 "-sound-" ?id2 )) (taken-by (str-cat ?ins1 "-sound-" ?ins2)) (synergy-level# (+ 1 (max ?s1 ?s2)))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::temperature-sounding-suite) " D" (call ?AIRS-MODIS getFactId) " S" (call ?AMSU getFactId) "}")))
    )

(defrule SYNERGIES::GRAVITY-measurements2 
    (declare (no-loop TRUE))
   ?this <- (REQUIREMENTS::Measurement (Parameter "5.1.1 Geoid and gravity field variations") (Id ?id1)
         (taken-by GRAVITY) (orbit-altitude# ?h) (orbit-anomaly# ?ano) (orbit-RAAN ?raan) (flies-in ?miss) (factHistory ?fh)) 
    ?sub <- (REQUIREMENTS::Measurement (Parameter "A9.Precise Orbit Determination") (taken-by CTECS) (flies-in ?miss) (Id ?id2) (orbit-altitude# ?h2) (orbit-anomaly# ?ano2) (orbit-RAAN ?raan2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    
   => 
   (modify ?this (Accuracy High) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::GRAVITY-measurements2) " " ?fh " S" (call ?sub getFactId) "}"))) 
   (assert (REQUIREMENTS::Measurement (Accuracy nil) (Accuracy# nil) (Accuracy2 nil) (All-weather nil) (avg-revisit-time-cold-regions# nil) (avg-revisit-time-global# nil) (avg-revisit-time-northern-hemisphere# nil) (avg-revisit-time-southern-hemisphere# nil) (avg-revisit-time-tropics# nil) (avg-revisit-time-US# nil) (band nil) (bias-calibration# nil) (cloud-cleared nil) (Continuity-over-time nil) (Coverage-of-region-of-interest Global) (Day-Night nil) (Field-of-view# nil) (flies-in ?miss) (Geometry nil) (High-lat-sensitivity nil) (Horizontal-Spatial-Resolution nil) (Horizontal-Spatial-Resolution# nil) (Horizontal-Spatial-Resolution2 nil) (Horizontal-Spatial-Resolution-Along-track nil) (Horizontal-Spatial-Resolution-Along-track# nil) (Horizontal-Spatial-Resolution-Cross-track nil) (Horizontal-Spatial-Resolution-Cross-track# nil) (Id GRAVITY2) (Instrument GRAVITY) (launch-date nil) (lifetime nil) (mission-architecture nil) (num-of-indep-samples# nil) (num-of-planes# nil) (num-of-sats-per-plane# nil) (On-board-calibration nil) (orbit-altitude# ?h) (orbit-anomaly# ?ano) (orbit-inclination nil) (orbit-RAAN ?raan) (orbit-type nil) (Parameter "3.2.6 Ocean mass distribution") (Penetration nil) (Pointing-capability High) (Polarimetry nil) (Radiometric-accuracy nil) (Radiometric-accuracy# nil) (Region-of-interest Global) (rms-system-instrument# nil) (rms-system-POD# nil) (rms-system-tropoH2O# nil) (rms-system-tropo-dry# nil) (rms-system-ionosphere# nil) (rms-system-model# nil) (rms-variable-angular-sampling# nil) (rms-variable-measurement# nil) (rms-system-tides# nil) (rms-variable-time-sampling# nil) (rms-total# nil) (sensitivity-in-cirrus nil) (sensitivity-in-convective-clouds nil) (sensitivity-in-high-winds nil) (sensitivity-in-low-troposphere-PBL nil) (sensitivity-in-upper-stratosphere nil) (sensitivity-in-upper-troposphere-and-stratosphere nil) (sensitivity-NEDT# nil) (sensitivity-over-lands nil) (sensitivity-over-oceans nil) (signal-to-noise-ratio# nil) (Spectral-region nil) (Spectral-resolution nil) (Spectral-resolution# nil) (Spectral-sampling nil) (Swath nil) (Swath# nil) (Swath2 nil) (synergy-level# nil) (taken-by GRAVITY) (Temporal-resolution Highest-1h-orless) (Temporal-resolution# nil) (ThreeD Some-3D-multi-angle) (Vertical-Spatial-Resolution nil) (Vertical-Spatial-Resolution# nil) (spectral-bands )(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::GRAVITY-measurements2) " A" (call ?this getFactId) " A" (call ?sub getFactId) "}"))))
   (assert (REQUIREMENTS::Measurement (Accuracy nil) (Accuracy# nil) (Accuracy2 nil) (All-weather nil) (avg-revisit-time-cold-regions# nil) (avg-revisit-time-global# nil) (avg-revisit-time-northern-hemisphere# nil) (avg-revisit-time-southern-hemisphere# nil) (avg-revisit-time-tropics# nil) (avg-revisit-time-US# nil) (band nil) (bias-calibration# nil) (cloud-cleared nil) (Continuity-over-time nil) (Coverage-of-region-of-interest Global) (Day-Night nil) (Field-of-view# nil) (flies-in ?miss) (Geometry nil) (High-lat-sensitivity nil) (Horizontal-Spatial-Resolution nil) (Horizontal-Spatial-Resolution# nil) (Horizontal-Spatial-Resolution2 nil) (Horizontal-Spatial-Resolution-Along-track nil) (Horizontal-Spatial-Resolution-Along-track# nil) (Horizontal-Spatial-Resolution-Cross-track nil) (Horizontal-Spatial-Resolution-Cross-track# nil) (Id GRAVITY3) (Instrument GRAVITY) (launch-date nil) (lifetime nil) (mission-architecture nil) (num-of-indep-samples# nil) (num-of-planes# nil) (num-of-sats-per-plane# nil) (On-board-calibration nil) (orbit-altitude# ?h) (orbit-anomaly# ?ano) (orbit-inclination nil) (orbit-RAAN ?raan) (orbit-type nil) (Parameter "4.1.3 glacier mass balance") (Penetration nil) (Pointing-capability High) (Polarimetry nil) (Radiometric-accuracy nil) (Radiometric-accuracy# nil) (Region-of-interest Cold-regions) (rms-system-instrument# nil) (rms-system-POD# nil) (rms-system-tropoH2O# nil) (rms-system-tropo-dry# nil) (rms-system-ionosphere# nil) (rms-system-model# nil) (rms-variable-angular-sampling# nil) (rms-variable-measurement# nil) (rms-system-tides# nil) (rms-variable-time-sampling# nil) (rms-total# nil) (sensitivity-in-cirrus nil) (sensitivity-in-convective-clouds nil) (sensitivity-in-high-winds nil) (sensitivity-in-low-troposphere-PBL nil) (sensitivity-in-upper-stratosphere nil) (sensitivity-in-upper-troposphere-and-stratosphere nil) (sensitivity-NEDT# nil) (sensitivity-over-lands nil) (sensitivity-over-oceans nil) (signal-to-noise-ratio# nil) (Spectral-region nil) (Spectral-resolution nil) (Spectral-resolution# nil) (Spectral-sampling nil) (Swath nil) (Swath# nil) (Swath2 nil) (synergy-level# nil) (taken-by GRAVITY) (Temporal-resolution Highest-1h-orless) (Temporal-resolution# nil) (ThreeD Some-3D-multi-angle) (Vertical-Spatial-Resolution nil) (Vertical-Spatial-Resolution# nil) (spectral-bands )(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::GRAVITY-measurements2) " A" (call ?this getFactId) " A" (call ?sub getFactId) "}")))) 
   (assert (REQUIREMENTS::Measurement (Accuracy nil) (Accuracy# nil) (Accuracy2 nil) (All-weather nil) (avg-revisit-time-cold-regions# nil) (avg-revisit-time-global# nil) (avg-revisit-time-northern-hemisphere# nil) (avg-revisit-time-southern-hemisphere# nil) (avg-revisit-time-tropics# nil) (avg-revisit-time-US# nil) (band nil) (bias-calibration# nil) (cloud-cleared nil) (Continuity-over-time nil) (Coverage-of-region-of-interest Global) (Day-Night nil) (Field-of-view# nil) (flies-in ?miss) (Geometry nil) (High-lat-sensitivity nil) (Horizontal-Spatial-Resolution nil) (Horizontal-Spatial-Resolution# nil) (Horizontal-Spatial-Resolution2 nil) (Horizontal-Spatial-Resolution-Along-track nil) (Horizontal-Spatial-Resolution-Along-track# nil) (Horizontal-Spatial-Resolution-Cross-track nil) (Horizontal-Spatial-Resolution-Cross-track# nil) (Id GRAVITY4) (Instrument GRAVITY) (launch-date nil) (lifetime nil) (mission-architecture nil) (num-of-indep-samples# nil) (num-of-planes# nil) (num-of-sats-per-plane# nil) (On-board-calibration nil) (orbit-altitude# ?h) (orbit-anomaly# ?ano) (orbit-inclination nil) (orbit-RAAN ?raan) (orbit-type nil) (Parameter "2.7.3 groundwater storage") (Penetration nil) (Pointing-capability High) (Polarimetry nil) (Radiometric-accuracy nil) (Radiometric-accuracy# nil) (Region-of-interest Global) (rms-system-instrument# nil) (rms-system-POD# nil) (rms-system-tropoH2O# nil) (rms-system-tropo-dry# nil) (rms-system-ionosphere# nil) (rms-system-model# nil) (rms-variable-angular-sampling# nil) (rms-variable-measurement# nil) (rms-system-tides# nil) (rms-variable-time-sampling# nil) (rms-total# nil) (sensitivity-in-cirrus nil) (sensitivity-in-convective-clouds nil) (sensitivity-in-high-winds nil) (sensitivity-in-low-troposphere-PBL nil) (sensitivity-in-upper-stratosphere nil) (sensitivity-in-upper-troposphere-and-stratosphere nil) (sensitivity-NEDT# nil) (sensitivity-over-lands nil) (sensitivity-over-oceans nil) (signal-to-noise-ratio# nil) (Spectral-region nil) (Spectral-resolution nil) (Spectral-resolution# nil) (Spectral-sampling nil) (Swath nil) (Swath# nil) (Swath2 nil) (synergy-level# nil) (taken-by GRAVITY) (Temporal-resolution Highest-1h-orless) (Temporal-resolution# nil) (ThreeD Some-3D-multi-angle) (Vertical-Spatial-Resolution nil) (Vertical-Spatial-Resolution# nil) (spectral-bands )(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::GRAVITY-measurements2) " A" (call ?this getFactId) " A" (call ?sub getFactId) "}")))) 
   (assert (REQUIREMENTS::Measurement (Accuracy nil) (Accuracy# nil) (Accuracy2 nil) (All-weather nil) (avg-revisit-time-cold-regions# nil) (avg-revisit-time-global# nil) (avg-revisit-time-northern-hemisphere# nil) (avg-revisit-time-southern-hemisphere# nil) (avg-revisit-time-tropics# nil) (avg-revisit-time-US# nil) (band nil) (bias-calibration# nil) (cloud-cleared nil) (Continuity-over-time nil) (Coverage-of-region-of-interest Global) (Day-Night nil) (Field-of-view# nil) (flies-in ?miss) (Geometry nil) (High-lat-sensitivity nil) (Horizontal-Spatial-Resolution nil) (Horizontal-Spatial-Resolution# nil) (Horizontal-Spatial-Resolution2 nil) (Horizontal-Spatial-Resolution-Along-track nil) (Horizontal-Spatial-Resolution-Along-track# nil) (Horizontal-Spatial-Resolution-Cross-track nil) (Horizontal-Spatial-Resolution-Cross-track# nil) (Id GRAVITY5) (Instrument GRAVITY) (launch-date nil) (lifetime nil) (mission-architecture nil) (num-of-indep-samples# nil) (num-of-planes# nil) (num-of-sats-per-plane# nil) (On-board-calibration nil) (orbit-altitude# ?h) (orbit-anomaly# ?ano) (orbit-inclination nil) (orbit-RAAN ?raan) (orbit-type nil) (Parameter "3.2.2 seafloor topography") (Penetration nil) (Pointing-capability High) (Polarimetry nil) (Radiometric-accuracy nil) (Radiometric-accuracy# nil) (Region-of-interest Global) (rms-system-instrument# nil) (rms-system-POD# nil) (rms-system-tropoH2O# nil) (rms-system-tropo-dry# nil) (rms-system-ionosphere# nil) (rms-system-model# nil) (rms-variable-angular-sampling# nil) (rms-variable-measurement# nil) (rms-system-tides# nil) (rms-variable-time-sampling# nil) (rms-total# nil) (sensitivity-in-cirrus nil) (sensitivity-in-convective-clouds nil) (sensitivity-in-high-winds nil) (sensitivity-in-low-troposphere-PBL nil) (sensitivity-in-upper-stratosphere nil) (sensitivity-in-upper-troposphere-and-stratosphere nil) (sensitivity-NEDT# nil) (sensitivity-over-lands nil) (sensitivity-over-oceans nil) (signal-to-noise-ratio# nil) (Spectral-region nil) (Spectral-resolution nil) (Spectral-resolution# nil) (Spectral-sampling nil) (Swath nil) (Swath# nil) (Swath2 nil) (synergy-level# nil) (taken-by GRAVITY) (Temporal-resolution Highest-1h-orless) (Temporal-resolution# nil) (ThreeD Some-3D-multi-angle) (Vertical-Spatial-Resolution nil) (Vertical-Spatial-Resolution# nil) (spectral-bands )(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::GRAVITY-measurements2) " A" (call ?this getFactId) " A" (call ?sub getFactId) "}")))) 
   )

(defrule SYNERGIES::fire-monitoring
    "identifies synergies between multispectral disaster monitoring and CO2 measurements to enable fire monitoring, and creates a new measurement with parameters Fire Monitoring and medium accuracy"
    ?this <- (REQUIREMENTS::Measurement (Id ?id1) (taken-by ?ins1) (Parameter "2.6.3 disaster monitoring") (Spectral-sampling ?ss &~Multispectral-10-100-channels &~Hyperspectral-100-channels-or-more))
    ?sub <- (REQUIREMENTS::Measurement (Id ?id2) (taken-by ?ins2) (Parameter "1.8.3 CO2") (Spectral-sampling Multispectral-10-100-channels))
    =>
    (duplicate ?this (Parameter "A2.Fire Monitoring") (Id (str-cat ?id1 "-syn-" ?id2 )) (Accuracy Medium)
         (taken-by (str-cat ?ins1 "-syn-" ?ins2)) (Spectral-sampling Multispectral-10-100-channels)(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::fire-monitoring) " D" (call ?this getFactId) " S" (call ?sub getFactId) "}")))
    )



(defrule SYNERGIES::CO2-temperature-error
    "identifies a synergy between a laser CO2 measurement error and a passive temperature measurement, where if the two measurements are taken together, the accuracy of the CO2 retrieval improves"
    ?CO2 <- (REQUIREMENTS::Measurement (Id ?id1) (taken-by ?ins1) (Parameter "1.8.3 CO2") (rms-system-tropoH2O# High)(factHistory ?fh))
    ?T <- (REQUIREMENTS::Measurement (Id ?id2) (taken-by ?ins2) (Parameter "1.2.1 Atmospheric temperature fields") (Spectral-region opt-SWIR))
    =>
    (modify ?CO2 (rms-system-tropoH2O# Low) (taken-by (str-cat ?ins1 "-syn-" ?ins2)) (Id (str-cat ?id1 "-syn-" ?id2 )) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::CO2-temperature-error) " " ?fh " S" (call ?T getFactId) "}")))
    )

(defrule SYNERGIES::CO2-pressure-error
    "identifies a synergy between laser CO2 measurements and passive O2 measurements, where if a CO2 measurement error is accompanied by a passive O2 measurement, the accuracy of the CO2 retrieval improves"
    ?CO2 <- (REQUIREMENTS::Measurement (Id ?id1) (taken-by ?ins1) (Parameter "1.8.3 CO2") (rms-system-tropo-dry# High)(factHistory ?fh))
    ?T <- (REQUIREMENTS::Measurement (Id ?id2) (taken-by ?ins2) (Parameter "1.8.6 O2") (Spectral-region opt-SWIR))
    =>
    (modify ?CO2 (rms-system-tropo-dry# Low) (taken-by (str-cat ?ins1 "-syn-" ?ins2)) (Id (str-cat ?id1 "-syn-" ?id2 )) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::CO2-pressure-error) " " ?fh " S" (call ?T getFactId) "}")))
    )

(defrule SYNERGIES::ocean-wind-vector-sensitivity-high-winds
    "identifies that combining a Ku-band measurement of ocean winds with a C-band measurement can improve sensitivity at high speed"
    (declare (salience 10) (no-loop TRUE))
    ?C <- (REQUIREMENTS::Measurement (Id ?id1) (taken-by ?ins1) (Parameter ?p) (Horizontal-Spatial-Resolution Very-low-10-100km) (sensitivity-in-high-winds High)) 
    ?Ku <- (REQUIREMENTS::Measurement (Id ?id2) (taken-by ?ins2) (Parameter ?p) (Horizontal-Spatial-Resolution Low-1km-10km) (sensitivity-in-high-winds Low)) 
    (test (meas-group ?p 3.4.0)) 
    (SYNERGIES::cross-registered (measurements $?m)) 
    (test (member$ ?id1 $?m)) 
    (test (member$ ?id2 $?m)) 
    =>
    (duplicate ?Ku (sensitivity-in-high-winds High) (taken-by (str-cat ?ins1 "-syn-" ?ins2)) (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::ocean-wind-vector-sensitivity-high-winds) " D" (call ?Ku getFactId) " S" (call ?C getFactId) "}")))
    )

(defrule SYNERGIES::ocean-wind-vector-complete
    "identifies the optimal wind measurement by combining a Ku-band measurement of ocean winds with a C-band measurement and a passive measurement, given specific criteria for spatial resolution and sensitivity, and creates a new measurement with the same attributes as the Ku-band measurement"
    (declare (salience 10) (no-loop TRUE))
    ?C <- (REQUIREMENTS::Measurement (Id ?id1) (taken-by ?ins1) (Parameter ?p) (Horizontal-Spatial-Resolution Very-low-10-100km) (sensitivity-in-high-winds High)) 
    ?Ku <- (REQUIREMENTS::Measurement (Id ?id2) (taken-by ?ins2) (Parameter ?p) (Horizontal-Spatial-Resolution Low-1km-10km) (sensitivity-in-high-winds Low)) 
    ?X <- (REQUIREMENTS::Measurement (Id ?id3) (taken-by ?ins3) (Parameter ?p)  (Horizontal-Spatial-Resolution Very-low-10-100km) (sensitivity-in-rain High)) 
    (test (meas-group ?p 3.4.0)) 
    (SYNERGIES::cross-registered (measurements $?m)) 
    (test (member$ ?id1 $?m)) (test (member$ ?id2 $?m)) (test (member$ ?id3 $?m)) 
    (not (REQUIREMENTS::Measurement (Parameter ?p) (Horizontal-Spatial-Resolution Low-1km-10km) (sensitivity-in-high-winds High) (sensitivity-in-rain High) (rms-system-tropoH2O# Low)))
    =>
    (duplicate ?Ku (sensitivity-in-high-winds High) (sensitivity-in-rain High) (rms-system-tropoH2O# Low) (taken-by (str-cat ?ins1 "-syn-" ?ins2 "-syn-" ?ins3)) (Id (str-cat ?id1 "-syn-" ?id2 "-syn-" ?id3))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::ocean-wind-vector-complete) " D" (call ?Ku getFactId) " S" (call ?C getFactId) " S" (call ?X getFactId) "}")))
    )

(defrule SYNERGIES::ocean-wind-vector-sensitivity-in-rain
    "identifies that combining a Ku-band measurement of ocean winds with a C-band measurement improves sensitivity at high speed in the presence of rain"
    (declare (salience 10) (no-loop TRUE))
    ?X <- (REQUIREMENTS::Measurement (Id ?id1) (taken-by ?ins1) (Parameter ?p)  (Horizontal-Spatial-Resolution Very-low-10-100km) (sensitivity-in-rain High)) 
    ?Ku <- (REQUIREMENTS::Measurement (Id ?id2) (taken-by ?ins2) (Parameter ?p) (Horizontal-Spatial-Resolution Low-1km-10km) (sensitivity-in-rain Low)) 
    (test (meas-group ?p 3.4.0)) 
    (SYNERGIES::cross-registered (measurements $?m)) 
    (test (member$ ?id1 $?m)) 
    (test (member$ ?id2 $?m)) 
    =>
    (duplicate ?Ku (sensitivity-in-rain High) (taken-by (str-cat ?ins1 "-syn-" ?ins2)) (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::ocean-wind-vector-sensitivity-in-rain) " D" (call ?Ku getFactId) " S" (call ?X getFactId) "}")))
    )

(defrule SYNERGIES::ocean-wind-vector-atmospheric-correction
    "identifies a synergy between a Ku-band measurement of ocean winds and an X-band passive measurement, where the accuracy of the retrieval improves when they are combined, and the rule uses the conditions of the measurements' parameters, horizontal-spatial-resolution, and rms-system-tropoH2O#, as well as a test for a specific measurement group, to trigger the duplication of the Ku-band measurement with improved accuracy."
    (declare (salience 10) (no-loop TRUE))
    ?X <- (REQUIREMENTS::Measurement (Id ?id1) (taken-by ?ins1) (Parameter ?p)  (Horizontal-Spatial-Resolution Very-low-10-100km) (rms-system-tropoH2O# Low)) 
    ?Ku <- (REQUIREMENTS::Measurement (Id ?id2) (taken-by ?ins2) (Parameter ?p) (Horizontal-Spatial-Resolution Low-1km-10km) (rms-system-tropoH2O# High)) 
    (test (meas-group ?p 3.4.0))  
    (SYNERGIES::cross-registered (measurements $?m)) 
    (test (member$ ?id1 $?m)) 
    (test (member$ ?id2 $?m)) 
    =>
    (duplicate ?Ku (rms-system-tropoH2O# Low) (taken-by (str-cat ?ins1 "-syn-" ?ins2)) (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::ocean-wind-vector-atmospheric-correction) " D" (call ?Ku getFactId) " S" (call ?X getFactId) "}")))
    )

(defrule SYNERGIES::cross-instrument-calibration-heritage-SCLP
    "identifies a synergy between the SCLP radiometer and SAR instruments, where if flown together, the calibration of the SAR is improved, and modifies the SAR measurement by setting the onboard calibration to High"
    ?SAR <- (REQUIREMENTS::Measurement (Parameter "4.2.1 snow-water equivalence") (Illumination Active) (On-board-calibration ?obc&~High) (taken-by ?ins1) (Id ?id1) (factHistory ?fh))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "4.2.1 snow-water equivalence") (Illumination Passive) (taken-by ?ins2) (Id ?id2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    =>
    (modify ?SAR (On-board-calibration High) (taken-by (str-cat ?ins1 "-syn-" ?ins2))
         (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::cross-instrument-calibration-heritage-SCLP) " " ?fh " S" (call ?sub getFactId) "}")))
    )

(deffunction increases-coverage3 (?orb1 ?orb2 ?orb3)
    ;(printout t (str-compare ?orb1 ?orb2) crlf)
    ;(printout t (str-compare ?orb1 ?orb3) crlf)
    ;(printout t (str-compare ?orb2 ?orb3) crlf)
    (if (or (neq (str-compare ?orb1 ?orb2) 0) (neq (str-compare ?orb1 ?orb3) 0) (neq (str-compare ?orb2 ?orb3) 0)) then (return TRUE) else (return FALSE))
    )

(defrule SYNERGIES::several-lidars-for-aerosols
    "identifies a synergy where having multiple lidars for aerosol extinction profiles/vertical concentration measurements with very low temporal resolutions can increase coverage, and generates a new measurement with medium temporal resolution that combines the measurements from the multiple lidars"
    ?m1 <- (REQUIREMENTS::Measurement (Parameter "1.1.4 aerosol extinction profiles/vertical concentration") (orbit-altitude# ?h1&~nil) (orbit-type ?typ1) 
        (orbit-RAAN ?raan1) (orbit-inclination ?inc1) (Temporal-resolution ?tr1)  (taken-by ?ins1) (Id ?id1))
    ?sub1 <- (REQUIREMENTS::Measurement (Parameter "1.1.4 aerosol extinction profiles/vertical concentration") (orbit-altitude# ?h2&~nil) (orbit-type ?typ2) 
        (orbit-RAAN ?raan2) (orbit-inclination ?inc2) (Temporal-resolution ?tr2)  (taken-by ?ins2&~?ins1) (Id ?id2&~?id1))
    ?sub2 <- (REQUIREMENTS::Measurement (Parameter "1.1.4 aerosol extinction profiles/vertical concentration") (orbit-altitude# ?h3&~nil) (orbit-type ?typ3) 
        (orbit-RAAN ?raan3) (orbit-inclination ?inc3) (Temporal-resolution ?tr3)  (taken-by ?ins3&~?ins2&~?ins1) (Id ?id3&~?id2&~?id1))
    (test (eq (str-index syn ?ins1) FALSE))
    (test (eq (str-index syn ?ins2) FALSE))
    (test (eq (str-index syn ?ins3) FALSE))
    (test (SameOrBetter Temporal-resolution ?tr1 Very-low-1-3-weeks))
    (test (SameOrBetter Temporal-resolution ?tr2 Very-low-1-3-weeks))
    (test (SameOrBetter Temporal-resolution ?tr3 Very-low-1-3-weeks))
    
    (test (eq (increases-coverage3 (str-cat ?typ1 "-" ?h1 "-" ?inc1 "-" ?raan1) (str-cat ?typ2 "-" ?h2 "-" ?inc2 "-" ?raan2) (str-cat ?typ3 "-" ?h3 "-" ?inc3 "-" ?raan3)) TRUE))
    =>
    (printout t "aerosol complete" crlf)
    (duplicate ?m1 (Temporal-resolution Medium-1day-3days) (taken-by (str-cat ?ins1 "-syn-" ?ins2 "-syn-" ?ins3)) (Id (str-cat ?id1 "-syn-" ?id2 "-syn-" ?id3))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::several-lidars-for-aerosols) " D" (call ?m1 getFactId) " S" (call ?sub1 getFactId) " S" (call ?sub2 getFactId) "}")))
    )

(defrule SYNERGIES::AOD-lidar-passive-combination
    "identifies that a combination of a lidar and a passive sensor can measure aerosol optical depth (AOD) with required vertical-spatial-resolution (VSR) and temporal-resolution (TR), using the cross-registered measurements, and creates a duplicate lidar measurement with the passive sensor's temporal-resolution and original lidar's vertical-spatial-resolution"
    ?lidar <- (REQUIREMENTS::Measurement (Parameter "1.1.1 aerosol height/optical depth") (Illumination Active) (Temporal-resolution ?tr1) (Vertical-Spatial-Resolution ?vsr1) (taken-by ?ins1) (Id ?id1))
    ?pass <- (REQUIREMENTS::Measurement (Parameter "1.1.1 aerosol height/optical depth") (Illumination Passive) (Temporal-resolution ?tr2) (Vertical-Spatial-Resolution ?vsr2) (taken-by ?ins2) (Id ?id2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    =>
    (duplicate ?lidar (Temporal-resolution ?tr2) (Vertical-Spatial-Resolution ?vsr1) (taken-by (str-cat ?ins1 "-syn-" ?ins2))
         (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::AOD-lidar-passive-combination) " D" (call ?lidar getFactId) " S" (call ?pass getFactId) "}")))
    )

(defrule SYNERGIES::NOx-strategy
    "identifies that a combination of a GEO and a LEO sensor can measure NOx in the troposphere with required VSR, TR, and sensitivity, and produces a new measurement with the same temporal resolution as the GEO sensor but with the higher sensitivity of the LEO sensor, as well as cloud-cleared, by cross-registering the two measurements and using a cloud mask measurement"
    ?GEO <- (REQUIREMENTS::Measurement (Parameter "1.8.7 NOx-NO, NO2-, N2O5, HNO3")  (Temporal-resolution ?tr1&Highest-1h-orless) (Vertical-Spatial-Resolution ?vsr1&~Medium-200m-2km&~Low-2km-or-greater) (sensitivity-in-low-troposphere-PBL Low) (taken-by ?ins1) (Id ?id1))
    ?LEO <- (REQUIREMENTS::Measurement (Parameter "1.8.7 NOx-NO, NO2-, N2O5, HNO3") (Temporal-resolution ?tr2&Medium-1day-3days) (Vertical-Spatial-Resolution ?vsr2&~nil) (sensitivity-in-low-troposphere-PBL ?tro&High) (taken-by ?ins2) (Id ?id2))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "1.5.4 cloud mask") (Id ?id3) (taken-by ?ins3) (synergy-level# ?s3&:(< ?s3 1)))
    (test (SameOrBetter Vertical-Spatial-Resolution ?vsr2 Medium-200m-2km))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (test (member$ ?id3 $?m))
    =>
    (duplicate ?LEO (Region-of-interest Global) (Temporal-resolution ?tr1) (Vertical-Spatial-Resolution ?vsr2) (sensitivity-in-low-troposphere-PBL ?tro) (cloud-cleared yes) (taken-by (str-cat ?ins1 "-syn-" ?ins2))
         (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::NOx-strategy) " D" (call ?LEO getFactId) " S" (call ?GEO getFactId) " S" (call ?sub getFactId) "}")))
    )

(defrule SYNERGIES::formaldehyde-strategy
    "identifies that a combination of a GEO and a LEO sensor can measure CH2OH with required Vertical-Spatial-Resolution, Temporal-resolution, and sensitivity in the troposphere, given that they have the same or better Vertical-Spatial-Resolution as the LEO sensor and are cross-registered with a cloud mask measurement, which can produce a new measurement of CH2OH, and the output is a duplicate of the LEO measurement with updated information"
    ?GEO <- (REQUIREMENTS::Measurement (Parameter "1.8.8 CH2O and non-CH4 VOC")  (Temporal-resolution ?tr1&Highest-1h-orless) (Vertical-Spatial-Resolution ?vsr1&~Medium-200m-2km&~Low-2km-or-greater) (sensitivity-in-low-troposphere-PBL Low) (taken-by ?ins1) (Id ?id1))
    ?LEO <- (REQUIREMENTS::Measurement (Parameter "1.8.8 CH2O and non-CH4 VOC") (Temporal-resolution ?tr2&Medium-1day-3days) (Vertical-Spatial-Resolution ?vsr2&~nil) (sensitivity-in-low-troposphere-PBL ?tro&High) (taken-by ?ins2) (Id ?id2))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "1.5.4 cloud mask") (Id ?id3) (taken-by ?ins3) (synergy-level# ?s3&:(< ?s3 1)))
    (test (SameOrBetter Vertical-Spatial-Resolution ?vsr2 Medium-200m-2km))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (test (member$ ?id3 $?m))
    =>
    (duplicate ?LEO (Region-of-interest Global) (Temporal-resolution ?tr1) (Vertical-Spatial-Resolution ?vsr2) (sensitivity-in-low-troposphere-PBL ?tro) (cloud-cleared yes) (taken-by (str-cat ?ins1 "-syn-" ?ins2))
         (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::formaldehyde-strategy) " D" (call ?LEO getFactId) " S" (call ?GEO getFactId) " S" (call ?sub getFactId) "}")))
    )

(defrule SYNERGIES::SO2-strategy
    "identifies that a combination of a GEO and a LEO sensor can measure SO2 with required vertical and temporal resolution and sensitivity in the troposphere, and produces a duplicate measurement with the same sensitivity but better vertical spatial resolution, by cross-registering both measurements and clearing clouds"
    ?GEO <- (REQUIREMENTS::Measurement (Parameter "1.8.11 SO2")  (Temporal-resolution ?tr1&Highest-1h-orless) (Vertical-Spatial-Resolution ?vsr1&~Medium-200m-2km&~Low-2km-or-greater) (sensitivity-in-low-troposphere-PBL Low) (taken-by ?ins1) (Id ?id1))
    ?LEO <- (REQUIREMENTS::Measurement (Parameter "1.8.11 SO2") (Temporal-resolution ?tr2&Medium-1day-3days) (Vertical-Spatial-Resolution ?vsr2&~nil) (sensitivity-in-low-troposphere-PBL ?tro&High) (taken-by ?ins2) (Id ?id2))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "1.5.4 cloud mask") (Id ?id3) (taken-by ?ins3) (synergy-level# ?s3&:(< ?s3 1)))
    (test (SameOrBetter Vertical-Spatial-Resolution ?vsr2 Medium-200m-2km))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (test (member$ ?id3 $?m))
    =>
    (duplicate ?LEO (Region-of-interest Global) (Temporal-resolution ?tr1) (Vertical-Spatial-Resolution ?vsr2) (sensitivity-in-low-troposphere-PBL ?tro) (cloud-cleared yes) (taken-by (str-cat ?ins1 "-syn-" ?ins2))
         (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::SO2-strategy) " D" (call ?LEO getFactId) " S" (call ?GEO getFactId) " S" (call ?sub getFactId) "}")))
    )

(defrule SYNERGIES::black-carbon-strategy
    "identifies that a GEO and a LEO sensor can measure SO2 in the troposphere with required Vertical Spatial Resolution (VSR), Temporal Resolution (TR), and sensitivity, and produces a new measurement by cross-registering the two sensors with a cloud mask parameter"
    ?GEO <- (REQUIREMENTS::Measurement (Parameter "1.8.13 Black carbon and other polluting aerosols")  (Temporal-resolution ?tr1&Highest-1h-orless) (Vertical-Spatial-Resolution ?vsr1&~Medium-200m-2km&~Low-2km-or-greater) (sensitivity-in-low-troposphere-PBL Low) (taken-by ?ins1) (Id ?id1))
    ?LEO <- (REQUIREMENTS::Measurement (Parameter "1.8.13 Black carbon and other polluting aerosols") (Temporal-resolution ?tr2&Medium-1day-3days) (Vertical-Spatial-Resolution ?vsr2&~nil) (sensitivity-in-low-troposphere-PBL ?tro&High) (taken-by ?ins2) (Id ?id2))
    ?sub <- (REQUIREMENTS::Measurement (Parameter "1.5.4 cloud mask") (Id ?id3) (taken-by ?ins3) (synergy-level# ?s3&:(< ?s3 1)))
    (test (SameOrBetter Vertical-Spatial-Resolution ?vsr2 Medium-200m-2km))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (test (member$ ?id3 $?m))
    =>
    (duplicate ?LEO (Region-of-interest Global) (Temporal-resolution ?tr1) (Vertical-Spatial-Resolution ?vsr2) (sensitivity-in-low-troposphere-PBL ?tro) (cloud-cleared yes) (taken-by (str-cat ?ins1 "-syn-" ?ins2))
         (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::black-carbon-strategy) " D" (call ?LEO getFactId) " S" (call ?GEO getFactId) " S" (call ?sub getFactId) "}")))
    )

(defrule SYNERGIES::atmospheric-humidity-sounding-strategy
    "identifies a synergistic measurement strategy where a GEO and a LEO sensor can measure atmospheric humidity profiles in the troposphere with required VSR, TR, and sensitivity, and generates a new measurement with fuzzy-maxed VSR"
    ?PATH <- (REQUIREMENTS::Measurement (Parameter "1.3.1 Atmospheric humidity -indirect-")  (Temporal-resolution ?tr1&Highest-1h-orless) (cloud-cleared yes) (Vertical-Spatial-Resolution ?vsr1&~nil) (sensitivity-in-low-troposphere-PBL ?tro1) (taken-by ?ins1) (Id ?id1))
    ?GPSRO <- (REQUIREMENTS::Measurement (Parameter "1.3.1 Atmospheric humidity -indirect-") (Temporal-resolution ?tr2&Medium-1day-3days) (cloud-cleared ?cc&~yes) (Vertical-Spatial-Resolution ?vsr2&~nil) (sensitivity-in-low-troposphere-PBL ?tro2) (taken-by ?ins2) (Id ?id2))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    =>
    (duplicate ?PATH (Region-of-interest Global) (Vertical-Spatial-Resolution (fuzzy-max Vertical-Spatial-Resolution ?vsr1 ?vsr2)) (taken-by (str-cat ?ins1 "-syn-" ?ins2))
         (Id (str-cat ?id1 "-syn-" ?id2 ))(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::atmospheric-humidity-sounding-strategy) " D" (call ?PATH getFactId) " S" (call ?GPSRO getFactId) "}")))
    )

(defrule SYNERGIES::water-vapor-transport-strategy
    "identifies a synergy between a GEO and a LEO sensor to measure water vapor transport in the troposphere, where the required Vertical Spatial Resolution (VSR), Temporal Resolution (TR), and sensitivity in the low troposphere Planetary Boundary Layer (PBL) are met, and duplicates the path with higher Horizontal Spatial Resolution and sensitivity, as well as a higher synergy level"
    ?PATH <- (REQUIREMENTS::Measurement (Parameter "1.3.2 Water vapor transport - Winds")  (Region-of-interest US) (Horizontal-Spatial-Resolution ?hsr1&Low-1km-10km) (Temporal-resolution ?tr1&Highest-1h-orless) (cloud-cleared yes) (Vertical-Spatial-Resolution ?vsr1&High-200m-orless) (sensitivity-in-low-troposphere-PBL High) (taken-by ?ins1) (Id ?id1) (synergy-level# 0))
    ?GPSRO <- (REQUIREMENTS::Measurement (Parameter "1.3.2 Water vapor transport - Winds") (Region-of-interest Global) (Horizontal-Spatial-Resolution ?hsr2&Low-1km-10km) (Temporal-resolution ?tr2&Highest-1h-orless) (cloud-cleared ?cc&~yes) (Vertical-Spatial-Resolution ?vsr2&Medium-200m-2km) (sensitivity-in-low-troposphere-PBL ?tro2&~High) (taken-by ?ins2) (Id ?id2) (synergy-level# 0))
    ?GACM <- (REQUIREMENTS::Measurement (Parameter "1.3.2 Water vapor transport - Winds") (Region-of-interest Global) (Horizontal-Spatial-Resolution ?hsr3&Medium-100m-1km) (Temporal-resolution ?tr3&Medium-1day-3days) (cloud-cleared ?cc3&~yes) (Vertical-Spatial-Resolution ?vsr3&nil) (sensitivity-in-low-troposphere-PBL ?tro3&High) (taken-by ?ins3) (Id ?id3) (synergy-level# 0))
    (SYNERGIES::cross-registered (measurements $?m))
    (test (member$ ?id1 $?m))
    (test (member$ ?id2 $?m))
    (test (member$ ?id3 $?m))
    =>
    (duplicate ?PATH (Region-of-interest Global) (Vertical-Spatial-Resolution High-200m-orless) (Horizontal-Spatial-Resolution Medium-100m-1km)
        (cloud-cleared yes) (sensitivity-in-low-troposphere-PBL High)  (Temporal-resolution Highest-1h-orless) (taken-by (str-cat ?ins1 "-syn-" ?ins2 "-syn-" ?ins3))
         (Id (str-cat ?id1 "-syn-" ?id2 "-syn" ?id3)) (synergy-level# 2)(factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::water-vapor-transport-strategy) " D" (call ?PATH getFactId) " S" (call ?GPSRO getFactId) " S" (call ?GACM getFactId) "}")))
    )


(defrule SYNERGIES::column-and-profile-ozone-measurements
    "identifies synergies between column and profile ozone measurements by duplicating the column measurement with higher accuracy and combining it with the profile measurement to produce a new measurement with a synergy level of 1"
    ?col <- (REQUIREMENTS::Measurement (Parameter "1.8.2 O3") (Id ?id1) (taken-by ?ins1) (Vertical-Spatial-Resolution nil) (Accuracy# 0.05) (synergy-level# 0))
    ?prof <- (REQUIREMENTS::Measurement (Parameter "1.8.2 O3") (Id ?id2) (taken-by ?ins2) (Vertical-Spatial-Resolution ?vsr&~nil) (synergy-level# 0))
    =>
    (duplicate ?col (Accuracy# 0.03) (taken-by (str-cat ?ins1 "-syn-" ?ins2))
         (Id (str-cat ?id1 "-syn-" ?id2 )) (synergy-level# 1) (factHistory (str-cat "{R" (?*rulesMap* get SYNERGIES::column-and-profile-ozone-measurements) " D" (call ?col getFactId) " S" (call ?prof getFactId) "}")))
    )

; create composite measurements like aerosol properties, cloud properties, tropo chemistry, ozone precursors

; complete chemistry measurements from ozone for instance? dangerous...

; aerosol measurements

; complete cloud measurements? dangerous...


