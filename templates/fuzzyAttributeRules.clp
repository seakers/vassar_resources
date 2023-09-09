
(defrule FUZZY::numerical-to-fuzzy-{{attribute}}

    ?m <- ({{template}}

{% if parameter.equalsIgnoreCase("all") %}
            ({{attribute}}# ?num&~nil)
{% else %}
            (Parameter "{{parameter}}")
            ({{shortenedAttribute}}# ?num&~nil)
{% endif %}
            ({{attribute}} nil)
            (factHistory ?fh))
    =>

    (bind ?value (numerical-to-fuzzy
                    ?num
                    (create${% for value in fuzzyValues %} {{value}}{% endfor %})
                    (create${% for min in mins %} {{min}}{% endfor %})
                    (create${% for max in maxs %} {{max}}{% endfor %})))
    ;(printout t "numerical-to-fuzzy-{{attribute}} " ?value crlf)
    (modify ?m ({{attribute}} ?value))
)