# Iteration 1 — Comentarios sobre el Draft del paper

> **Contexto.** Trabajaremos primero en Google Docs y luego convertiremos a Word. **Nada de LaTeX.** Las propuestas de texto van como prosa lista para copiar/pegar al doc.

---

## Comentarios generales

### General 1 — Armonización de parent education (lo que Tom pidió)

**Lo que pasa hoy.** La armonización actual (colapsar W7–W10 nuevas categorías 4/5/6 → legacy 4) es lo único que evita un *cambio de escala* mid-panel, pero **introduce un artefacto a la baja en los waves tardíos** porque tres categorías nuevas se mapean a una sola legacy. Eso explica el 5.17 → 3.88 que Tom ve.

**Propuesta de armonización (la limpia y la que sugeriría a Tom).**
Tratar parent education como **time-invariant** dentro del estudiante: para cada `record_id`, tomar la **primera observación no-NA en W1–W6** (la escala legacy de 7-categorías original) y propagarla a todas las olas. Las observaciones de W7–W10 se descartan para ese covariate. La justificación es:

- Within-student variation en `par_edu` es esencialmente cero (mismos padres con la misma educación).
- W1–W6 usaron la escala original sin contaminación.
- La covariable sigue entrando a la regresión como número 1–7 (ordinal); el coeficiente apenas debería cambiar (la varianza within-student no estaba aportando casi nada de info).

**Impacto en la Tabla 1.** La fila "Parent Education" colapsa a **un solo valor** (baseline = follow-up por construcción). Eso resuelve el "5.17 → 3.88" de un golpe: ya no hay decrecimiento que justificar.

**Impacto en la sección de Resultados.** La frase actual:

> *"Parental education decreased from 5.17 (some College) to 3.88 ();"*

se reemplaza por:

> *"Parental education averaged 5.16 (between* high school graduate *and* some college*) across the analytic sample, treated as a time-invariant covariate (first reported value from the W1–W6 legacy 7-level scale)."*

(El 5.16 es estimado — habrá que recalcular con la armonización fija; será muy cercano a 5.17.)

**Acción técnica concreta.** Cambiar en [R/01-advance-panel.R](R/01-advance-panel.R) la lógica de LOCF de `par_edu` por: tomar el primer no-NA de W1–W6 por estudiante y propagarlo. Confirmar luego que la regresión §13.1 no cambia en los demás coeficientes. Refittear y regenerar Tabla 1.

---

### General 2 — Reescribir el párrafo de out/in degree

**Reemplazo propuesto.** El párrafo:

> *"Average network out-degree was 2.62 at baseline and 2.49 at follow-up. Perceived friends e-cigarette use was 0.38 and increased slightly to 0.42; whereas network exposure was 0.02 and 0.66, respectively. Network exposure to quitters was zero at baseline and increased to 0.036 at follow-up."*

→ pasa a ser:

> *"Average network out-degree was 2.62 at baseline (spring 9th grade) and 2.49 at follow-up (spring 12th grade). In-degree took slightly lower mean values (2.57 and 2.45). Out- and in-degree are computed on the full per-school friendship network at each wave — over the complete wave universe they coincide exactly (by graph identity, the total nominations sent equal the total nominations received) — and the small gap reported here reflects the fact that Table 1 summarizes a subset of the panel (the 1,962 students who completed seven or more waves). Edges that connect a Q ≥ 7 student to a non-Q ≥ 7 peer contribute asymmetrically to the in- and out-degree averages within the subset. Perceived friend use was 0.38 at baseline and rose slightly to 0.42 at follow-up. The network-derived peer-use exposure rose more sharply, from 0.020 to 0.066, reflecting the growing prevalence of vaping across high school. Network exposure to disadopters was zero at baseline (no observed quitters at the first wave) and reached 0.036 by follow-up."*

Nota: el "0.02 y 0.66" del draft actual es un **typo** — el valor follow-up es **0.066**, no 0.66 (un orden de magnitud). Lo corregí arriba.

---

### General 3 — Párrafo introductorio de Tablas 3 y 4 (con Cochran–Armitage)

**Reemplazo propuesto** del párrafo actual:

> *"As the number of perceived friends increased, increases the quit rate decreased dramatically from 54.12% to 20.73%. Similarly, with network exposure to quitters, as the number of friends who use e-cigarettes increased, the quit rate decreased from 52.14% to 0.0%"*

→ Reescritura completa:

> *"Tables 3 and 4 report the unadjusted relationship between peer-use environment in the prior wave and the probability of any 1 → 0 transition in the next wave. The two tables use the two operationalizations of peer use described in Measures: perceived friend use (PFU, self-reported by the ego, 0–5 close friends; Table 3) and the network-derived count of nominated friends who reported using at the prior wave (Table 4).*
>
> *In Table 3, the quit rate declines monotonically as perceived friend use increases, from 54.12% at zero perceived using friends down to 20.73% at five — a 2.6-fold drop. A Cochran–Armitage trend test on the proportions confirms that this gradient is highly significant (χ²(1) = 91.9, p < 0.001); equivalently, a logistic regression of the binary quit outcome on PFU as a linear predictor yields an odds ratio of 0.72 per one-friend increase (95% CI 0.67 – 0.77; z = −9.35).*
>
> *In Table 4, the gradient is in the same direction but gentler. The quit rate falls from 52.14% (zero using friends in the network) to 29.41% (three using friends), and the trend is also significant (χ²(1) = 12.0, p < 0.001; logistic OR per additional using friend = 0.75, 95% CI 0.63 – 0.88). The 4-using-friends and 5+-using-friends rows are based on only 5 and 2 person-waves, respectively, and should be read as essentially anecdotal — the apparent 40.00% / 0.00% values reflect sampling noise rather than a regime change at high exposure. The two channels therefore yield convergent gradients, with the steeper effect coming from self-reported perception."*

(Reemplaza también el "0.0%" del párrafo introductorio por evitar afirmaciones de point estimates con n=2.)

---

### General 4 — Sección "Results" reescrita (propuesta completa)

> **Results**
>
> A total of 1,962 students contributed at least seven consecutive waves of past-6-month e-cigarette use and were retained for the analytic sample (Table 1; Q-restriction rationale in *Methods* and Supplementary S1). Past-6-month e-cigarette use prevalence rose from 2.1% at baseline (spring 9th grade) to 5.6% at follow-up (spring 12th grade), and the share of students who reported quitting in the current wave grew from 0.5% to 3.3%. The cohort 2 (class of 2025) share was 37.4%; the sample was 58% female, 25% sexual-minority, 47–58% Asian, and 39% Hispanic/Latine. RCADS subscale means were stable across high school: 0.945 → 0.941 for major depressive symptoms and 1.159 → 0.982 for generalized anxiety symptoms.
>
> Network out-degree averaged 2.62 nominations sent at baseline and 2.49 at follow-up, with in-degree only marginally smaller (2.57 and 2.45). Out- and in-degree are computed on the complete per-school friendship network and therefore coincide exactly when averaged over the whole wave universe; the small gap visible in Table 1 reflects the subset restriction (Q ≥ 7 students) — edges crossing the subset boundary contribute asymmetrically to the two means. Perceived friend use (PFU, 0–5 close friends) drifted from 0.38 to 0.42. Network-derived exposure to current users moved more sharply (0.020 → 0.066), and exposure to dis-adopters — by construction zero at baseline because no prior wave existed — reached 0.036 by spring of 12th grade.
>
> Table 2 reports the four event-history logistic regressions for first-time adoption, stable disadoption, experimental (any) disadoption, and unstable (cyclic) disadoption. The two peer-use channels behave **symmetrically on adoption**: each one-step increase in PFU multiplied the odds of first-time adoption by 1.47 (p < 0.001), and a fully using-friend network (network exposure = 1) multiplied them by 5.68 (p < 0.001). The same two channels behave **symmetrically on stable disadoption but in the opposite direction**: each PFU step lowered the odds of stable quitting by 27% (OR = 0.73, p = 0.022), and full network exposure lowered them by an order of magnitude (OR = 0.10, p = 0.011). The experimental-disadoption column reproduces this pattern (PFU OR = 0.72, p = 0.002; network-exposure OR = 0.23, p = 0.031). What is **asymmetric** is the role of exposure to dis-adopters themselves: the network-exposure-to-disadopters covariate did not reach significance in any of the four outcomes (point estimates of 1.81, 0.37, 0.40, 0.04). Quitting therefore appears not to diffuse from peer to peer in the same direct way that use does; instead, the dominant peer-environment signal on quitting is the *absence* of using friends, not the *presence* of recently-quitting friends.
>
> Beyond peer exposure, sexual minorities had higher odds of first-time adoption (OR = 1.45, p < 0.05), Asian students had lower odds (OR = 0.64, p < 0.05), and ego in-degree (popularity) carried a small positive association (OR = 1.10, p < 0.05). Mental health entered the disadoption columns rather than the adoption column: depressive symptoms (MDD) predicted lower odds of experimental disadoption (OR = 0.44, p = 0.006) and of unstable cyclic disadoption (OR = 0.21, p = 0.023), consistent with the literature linking depressive symptoms to quit-attempt failure. Generalized anxiety did not reach significance in any column.
>
> Tables 3 and 4 strip the peer-use gradients down to raw quit rates at the person-wave level (no adjustment, no random intercept). Both tables tell the same story as Table 2 but in unadjusted form. In Table 3 the quit rate falls from 54.12% (PFU = 0) to 20.73% (PFU = 5), a 2.6-fold drop; the trend is highly significant (Cochran–Armitage χ²(1) = 91.9, p < 0.001; logistic OR per PFU step = 0.72, 95% CI 0.67–0.77). Table 4, using the network-derived count of using friends instead of PFU, replicates the direction with a gentler slope: 52.14% → 29.41% over k = 0 → 3 using friends (χ²(1) = 12.0, p < 0.001; logistic OR per friend = 0.75, 95% CI 0.63–0.88). The two highest-exposure rows in Table 4 (k = 4 and k = 5+, n = 5 and n = 2 person-waves) carry essentially no information and should be read as sampling noise.
>
> Figure 1 places these patterns on a calendar axis. Disadoption rate is largely flat across high school (46.7% in spring 9th, drifting to 50.0% in spring 12th), whereas adoption follows the well-known inverted-U: 2.6% in spring 9th, rising to a maximum of 5.6% in spring 11th, falling back to 3.1% by spring 12th. The two trajectories together imply that the active-user pool is replenished early and then shrinks late, with disadoption running at a near-constant rate underneath.
>
> Figure 2 visualizes this co-evolution at the network level for one focal school (School 114, the highest-event school in the panel: 115 first-time adoptions and 81 dis-adoptions across W2–W8). Each panel fixes node positions using a Fruchterman-Reingold layout computed on the union of observed friendship nominations and colors each student by their e-cigarette status at that wave: current user (blue), dis-adopter (red), never-user (grey), missing (white). The figure shows the active-user pool growing through 11th grade and contracting at 12th grade as dis-adopters accumulate; visual clustering of users and dis-adopters is suggestive but is more rigorously characterized by the regression estimates in Table 2.

---

### General 5 — Explicación al estilo "abuela" para el párrafo 1 de Discussion

> *Si tienes amigos que fuman mucho, y tú también fumas, lo más difícil para que tú dejes de fumar es **que sigan habiendo amigos fumadores a tu alrededor**. Eso lo dice el estudio claramente: cuantos más amigos fuman, menos probable que tú dejes.*
>
> *Lo que parece extraño es lo siguiente: si tener amigos que fuman te dificulta dejarlo, uno esperaría que **tener amigos que ya dejaron de fumar** te ayude a dejarlo. Pues no — al menos no en esta etapa de la vida (la adolescencia). ¿Por qué no?*
>
> *Imagina un grupo de 100 amigos. En cualquier momento, sólo unos pocos (digamos 5) son fumadores activos, y de esos 5 quizás sólo 1 o 2 acaban de dejar de fumar en el último semestre. Esos 1–2 ex-fumadores son **muy poquitos** para crear una "presión social" que te empuje a tí también a dejarlo. En cambio, los 5 fumadores activos son una presión social grande y constante. Por eso lo que mueve la aguja para dejar de fumar es **que esa presión activa desaparezca** (que tus amigos fumadores dejen de estar fumando), no que aparezcan modelos visibles de quitters.*
>
> *Dicho de otra forma: el "veneno" para dejar de fumar es el ambiente cargado de uso. El "antídoto" no es ver a alguien que ya dejó, sino que el ambiente se aclare. En la adolescencia, donde la presión social y el comportamiento de los pares es lo más fuerte, esto se observa con mucha claridad.*

Para el paper, una sola línea integrable a la Discussion:

> *"Even when peer cessation events are observable, they remain too rare in adolescent friendship networks to constitute a meaningful 'reverse-diffusion' signal: at any given wave only a small fraction of nominated friends are recent quitters, so the dominant peer-environment information bearing on an ego's own quitting decision is the level of *active* use among friends, not the count of friends who have just stopped."*

---

### General 6 — Dónde referenciar `S1 - Q-sensitivity`

En el Methods (donde dice "We restrict the present analyses to students who completed seven waves of data. In supplementary graph S1 we show that this provides the maximum increase in the number of events"), la referencia **ya está bien** — es el lugar natural para introducir la decisión de Q = 7.

En Discussion, el párrafo de "robust across multiple analytic specifications and variations in the number of survey waves included" **gana mucho con un puntero explícito**. Cambio sugerido:

> *"... and we observe that these patterns were robust across multiple analytic specifications and variations in the number of completed survey waves included (Supplementary S1 — Q-sensitivity; Supplementary S2 — Robustness regressions at Q = 6, 5, 4)."*

Lo que **no** recomiendo es repetir la cita de S1 en más lugares (Results no la necesita — la mención del Q = 7 ya está en Methods, y arrastrar más referencias rompe el flujo). Una vez en Methods + una vez en Discussion alcanza.

---

### General 7 — Qué debería ir en Supplementary Material

Lista sugerida — cada item es **una sección del SM** con su propósito en una línea:

- **S1 — Q-sensitivity.** Por qué Q = 7. Gráfica `sec11_Q_sensitivity.pdf` + tabla de N estudiantes / N eventos por outcome × Q (de §11.5 del internal report).
- **S2 — Robustness regressions at Q = 6, 5, 4.** Misma especificación que Tabla 2 pero a tres Qs más relajados, mostrando que los coeficientes clave (PFU, network-users, MDD) se mantienen significativos y del mismo signo.
- **S3 — Block-buildup (B1 → B5).** Cómo cambian las ORs cuando los predictores se agregan en bloques (demográficos → mental health → out/in degree → PFU → network exposures). Demuestra que ningún coeficiente clave es artifact de colinealidad. (De §13.4 del internal report.)
- **S4 — Regression diagnostics.** Los 9 diagnostics ya armados (D1 separation, D2 VIF, D3 Firth, D4 linearity-in-continuous, D5 cluster-robust SE, D6 AUC + Brier, D7 Cook's distance / leverage, D8 random-effect variance, D9 leave-one-school-out). (De §13.3.)
- **S5 — Alternative peer-cessation operationalisations.** Es **clave** porque la Discussion menciona PFU_D. Reportar `anyQuit`, `ΔPFU`, `PFU↓`, `ΔE_users` y **PFU_D** como variantes del bloque 5 — mostrando que PFU_D sí entra significativo donde el `E_D` estructural no, justificando la frase de la Discussion. (De §13.5.)
- **S6 — Sample characteristics, extended.** Las dos variantes de Table 1 que no están en el paper: (a) "broadest" (todos los panel students en gs = 2 y gs = 8 — distintos estudiantes en cada columna), (b) "paired" (mismos estudiantes en ambas olas, n = 2,522). Útiles para mostrar selección entre los tres rosters. (De §13.2.)
- **S7 — Descriptive associations.** Distribución de out-degree por uso de e-cigs ego, distribución de `k_users` por wave, gráfica de adoption/disadoption × HS grade-semester (`sec11_grade_rates_line.pdf`). (De §11.1, §11.4.)
- **S8 — Per-wave network plots, full set.** El 4 × 2 grid con las 8 olas de School 114 (`network_panel_school114_allwaves.pdf`), no sólo los 4 frames del paper.
- **S9 — Codebook.** Pequeña tabla con todas las variables del modelo y su definición exacta (medición, escala, lag).

Si terminamos publicando el SAOM exploratorio (no creo en este paper, sí en uno follow-up de métodos), iría como **S10 — SAOM co-evolution analysis (exploratory)**.

---

### General 8 — Edit a "This rules out the simple 'perception is a noisy proxy for reality' reading"

El "individual characteristics are relevant" que propones **mezcla dos ideas distintas en una sola oración**:

1. *El primer párrafo* (donde aparece la frase) habla específicamente del **canal peer-context**: PFU y network exposure son dos cosas distintas, no la misma cosa medida con ruido.
2. *El siguiente párrafo* abre justamente con: *"On the other hand, beyond the online context, individual mental health has become a consistent predictor..."* — ése es donde aparece la idea de "los rasgos individuales también pesan".

Si mezclas las dos en la frase de "perception is a noisy proxy", el lector se confunde porque "individual characteristics" no se ha mencionado todavía en ese párrafo. **Mi sugerencia**: dejar el primer párrafo enfocado en el contraste perception-vs-network y reforzar la conclusión sin colar individual characteristics:

> *"This rules out the simple 'perception is a noisy proxy for reality' reading and indicates that two distinct social channels — direct exposure to friends who use, and the ego's cognitive representation of how prevalent use is in their environment — each carry independent information about whether a current user will quit."*

Y entonces la transición al segundo párrafo ya enlaza con individual characteristics de forma natural:

> *"On the other hand, **beyond the peer-context channels above,** individual mental health has become a consistent predictor of non-use patterns. ..."*

(Cambié "beyond the online context" — que no encaja del todo — por "beyond the peer-context channels above". El "online context" parece un typo / residuo.)

---

### General 9 — Discussion: qué falta + énfasis en la asimetría

La sección Discussion cubre bien (i) perception ≠ network exposure, (ii) MDD como barrera de cesación, (iii) timing/inverted-U, (iv) la extensión metodológica, (v) limitaciones, (vi) future work. Lo que **no** está suficientemente subrayado:

**La asimetría exacta — falta un párrafo dedicado.** Ahora mismo la asimetría aparece dispersa: se dice que disadoption no es adoption-en-reverso, pero no se contrasta directamente el patrón completo. Propongo un párrafo nuevo al inicio de la Discussion (o como segundo párrafo, después del primero que ya tienes), con esta forma:

> ***Symmetry and asymmetry in the peer-context signal.** A central finding is that the two channels of peer-use exposure — perception and network — behave **symmetrically** for first-time adoption and for stable disadoption: both push the odds of adoption up (PFU OR = 1.47, network-users OR = 5.68) and both push the odds of stable disadoption down (PFU OR = 0.73, network-users OR = 0.10). In that sense, the same peer-environment signal that draws an adolescent into use also holds them in use once they have adopted. What is **asymmetric** is the role of peer disadoption itself: exposure to friends who have recently quit did not predict any of the four outcomes (network exposure to dis-adopters OR = 1.81 / 0.37 / 0.40 / 0.04, none significant). Redmond's (1996) proposal that cessation diffuses through social systems the way adoption does is therefore only partially supported in this adolescent context — the diffusion of quitting does not run through peer-quitter exposure, but rather through the **absence** of peer-user exposure. We discuss the substantive and methodological implications of this asymmetry below.*

(Sirve como tesis-frase de toda la Discussion. Las secciones posteriores entonces son comentarios sobre cada pieza de esta asimetría.)

**Segundo refuerzo en el cierre.** En el último párrafo de la Discussion (donde se habla del SAOM y de PFU_D), conviene volver a citar la asimetría una vez más:

> *"... Overall, future work should further examine whether the asymmetric peer-context pattern documented here — peer-user exposure operative, peer-quitter exposure null — generalizes to other adolescent risk behaviors including cannabis and alcohol use."*

---

### General 10 — Extensión: framework para estudios que no capturan toda la adopción

**Dónde ponerlo.** Después del párrafo de "Our methodological approach – treating disadoption as a discrete event-history outcome..." y antes de las "Several limitations should be noted". Sería un nuevo párrafo en la misma sección "methodological extension". Propuesta:

> *"This re-framing is especially valuable for substance-use studies that enter the field **after** the initial adoption curve has already saturated — that is, when prevalence is high at the first observed wave and few new uptake events are expected in the observation window. Classical adoption-only models face a structural ceiling in such cohorts: there is little new behavior to predict, and intervention design is correspondingly underspecified. Treating disadoption as the primary event of interest reverses the question — who exits use, and is the exit stable, episodic, or unstable — and shifts intervention design from prevention of uptake to mitigation of established use. Examples where this re-orientation is particularly pertinent include adult heavy-drinker cohorts entering treatment studies, college-age cannabis users observed only post-college-entry, and adult cigarette smokers in late-stage tobacco-control campaigns where prevalence is high but the bulk of initiation took place years earlier. In each of these, peer-network exposure remains observable and informative; it just acts on the dis-adoption side rather than on the adoption side."*

**Más casos donde el framework aplica.**

1. **Adultos en estudios de cesación de tabaco** ya muy avanzados (e.g., los cohortes US que comienzan tras el peak de prevalencia adulta de los 80s).
2. **Trastornos de uso de alcohol en adultos jóvenes universitarios**: ingresan al estudio ya con consumo establecido en >60% de la muestra; la pregunta sustantiva es quién deja vs quién persiste.
3. **Cannabis recreacional en jurisdicciones recién legalizadas**: tras el shock inicial de adopción, lo interesante es la disadoption y sus determinantes — y los pares siguen siendo el motor del comportamiento.
4. **Adherencia a medicación crónica** (estatinas, anti-hipertensivos): adopción es por prescripción médica, no peer-driven, pero **dis-adopción** (abandono) sí depende del entorno social/familiar — el framework es directo.
5. **Disadoption de pantallas / redes sociales en adolescentes**: prevalencia ~100% al inicio del estudio; lo interesante es quién reduce uso y por qué (peer dinámicas relevantes).
6. **Patrones de mascarilla post-pico de la pandemia COVID**: dis-adopción del uso de mascarilla con clear peer-environment dynamics.

---

## Comentarios menores

### Minor 1 — Edit a la definición de outcome (4)

**Apruebo con un refinamiento.** Tu propuesta:

> *"(4) Unstable disadoption when a user reports not using and then subsequently reports using again in the next measurement wave. **In the last case,** multiple events per student are allowed and the model is fit with a person-level random intercept."*

ya queda mucho más claro (la frase original ambiguamente sugería que TODOS los outcomes permitían eventos múltiples + RE intercept, cuando en realidad esto es **exclusivo** del outcome 4). Mi propuesta de refinamiento adicional, para no dejar dudas sobre cómo se modelan los otros tres:

> *"(4) Unstable disadoption when a user reports not using and then subsequently reports using again in the next measurement wave. **Only outcome (4) allows multiple events per student and is fit with a person-level random-intercept (mixed-effects) logistic model; outcomes (1)–(3) each contribute one event per student and are fit with fixed-effects logistic regression with cluster-robust standard errors at the school level."***

(Es más explícito sobre qué hace cada uno y elimina la ambigüedad de "the model" — ¿cuál de los cuatro?)

Esto coincide exactamente con la implementación en [R/04-regressions.R](R/04-regressions.R): outcome C (= Unstable, = 4) usa `glmer(..., (1 | record_id))`, los otros tres usan `glm + sandwich::vcovCL`.

---

### Minor 2 — Tamaño de letras de `sec11_Q_sensitivity.pdf` y `sec11_grade_rates_line.pdf`

**Comparto el diagnóstico**: las letras se sienten chicas para el tamaño del plot. Aquí están las líneas exactas y los cambios sugeridos.

**`sec11_grade_rates_line.pdf`** — en [R/05e-grade-rate-table.R](R/05e-grade-rate-table.R):

| Línea | Actual | Sugerido |
|:-:|:--|:--|
| 136 | `colour = "Adoption (0→1)"), size = 2.6) +` | `... size = 3.4) +` |
| 139 | `colour = "#1f77b4", vjust = -1.0, size = 3) +` | `... size = 3.8) +` |
| 144 | `colour = "Disadoption (any 1→0)"), size = 2.6) +` | `... size = 3.4) +` |
| 147 | `colour = "#2ca02c", vjust = 1.7, size = 3) +` | `... size = 3.8) +` |
| 160 | `theme_bw(base_size = 11) +` | `theme_bw(base_size = 13) +` |
| 168 | `axis.text.x = element_text(size = 8))` | `axis.text.x = element_text(size = 11))` |
| 171 | `width = 10, height = 4.6, dpi = 220)` | `width = 9, height = 4.4, dpi = 220)` (opcional — empuja más relación letra/área) |

**`sec11_Q_sensitivity.pdf`** — en [R/05h-Q-sensitivity.R](R/05h-Q-sensitivity.R):

| Línea | Actual | Sugerido |
|:-:|:--|:--|
| 212 | `geom_text(aes(label = value), vjust = -0.9, size = 3, ...)` | `... size = 3.6, ...` |
| 215 | `vjust = 1.9, size = 2.7, show.legend = FALSE) +` | `vjust = 1.9, size = 3.3, show.legend = FALSE) +` |
| 218 | `vjust = 1.9, size = 3.4, fontface = "bold", ...)` | `vjust = 1.9, size = 4.0, fontface = "bold", ...)` |
| 229 | `theme_bw(base_size = 11) +` | `theme_bw(base_size = 13) +` |

**Para correr y regenerar los plots a mano**, desde la raíz del repo:

```bash
Rscript R/05e-grade-rate-table.R
Rscript R/05h-Q-sensitivity.R
```

Sobrescribirá los PDFs en `outputs/figures/`. Si quieres ir afinando los tamaños iterativamente, abre el PDF resultante después de cada corrida.

---

## Resumen ejecutivo de cambios accionables

| # | Acción | Prioridad |
|:-:|:--|:-:|
| G1 | Refactor `par_edu` a time-invariant (first non-NA W1–W6) y refit Table 1 + §13.1 | **Alta** (Tom lo pidió) |
| G2 | Reescribir párrafo out/in degree con la explicación del subset-effect | Alta |
| G3 | Reescribir párrafo intro de Tablas 3 y 4 + agregar Cochran–Armitage | Alta |
| G4 | Considerar la "Results" reescrita como base para iterar | Media |
| G5 | Insertar el párrafo "abuela" como una oración en Discussion | Baja |
| G6 | Añadir puntero a S1 en el párrafo de robustness de Discussion | Baja |
| G7 | Estructurar el SM en S1–S9 | Alta (preparar paralelo) |
| G8 | Editar "rules out perception-as-noisy-proxy" + ajustar transición al párrafo MDD | Media |
| G9 | Añadir párrafo "Symmetry and asymmetry" al inicio de la Discussion | **Alta** |
| G10 | Añadir párrafo sobre cohortes saturated-at-baseline en la sección de extensiones metodológicas | Media |
| M1 | Aprobar edit a outcome (4) con refinamiento adicional | Baja |
| M2 | Bumpear tamaños de letra en `R/05e` y `R/05h`, re-correr | Baja |
