# Manipulación de datos hecha fácil con data.table

Taller a cargo del Ing. Guillermo García para el Grupo de Usuaries de R en Rosario
18 de febrero de 2021, Rosario, Argentina

## ¿Por qué data.table?

. Es 100% compatible con los data.frame
. Manejo eficiente de grandes volúmenes de datos
. Sintaxis muy simple y muy amigable para hacer mucho más que con los data.frame

## ¿Cómo se usa y su paralelismo con el SQL?
dt[i, j, by]
i:WHERE / ORDER BY
j:SELECT / UPDATE
by: GROUP BY

## ¿Y qué pasa con dplyr?
* Buena pregunta…
* No sé… no uso dplyr :-P
* Existe **dtplyr**, una versión de dplyr que traduce su sintaxis a data.table (!!!) para ser más eficiente.
* La sintaxis… es cuestión de gustos
