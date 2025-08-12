library(tidyverse)
library(here)

var_names_sort <- c("intercept",
                    "Year 2017 (relative to 2009)",
                    "log(household income)",
                    "Vehicles per driver",
                    "Non-working father",
                    "Non-working mother",
                    "Age",
                    "Female",
                    "Has younger sibling",
                    "Has older sibling",
                    "log(trip distance)",
                    "log(density)")

var_names_file <- c("intercept",
                    "Age",
                    "Female",
                    "Has older sibling",
                    "Has younger sibling",
                    "log(density)",
                    "log(trip distance)",
                    "log(household income)",
                    "Non-working father",
                    "Non-working mother",
                    "Vehicles per driver",
                    "Year 2017 (relative to 2009)")

var_names <- factor(rep(var_names_file, 2), levels = var_names_file) |>
  sort()

results_no_nest <- here("code",
                        "models",
                        "no-nest",
                        "result.csv") |>
  read_csv() |>
  mutate(variable = as.character(var_names),
         alternative = rep(c("Utility of car travel\n(relative to escorted active)",
                             "Utility of unescorted active travel\n(relative to escorted active)"), 12)) |>
  mutate(model = "Unnested")

var_names_cross_file <- c("alpha_active", as.character(var_names), "mu_active", "mu_parent")

results_cross_nest <- here("code",
                           "models",
                           "cross-nest-mode-ind",
                           "result.csv") |>
  read_csv() |>
  mutate(variable = as.character(var_names_cross_file),
         alternative = c("na", rep(c("Utility of car travel\n(relative to escorted active)",
                             "Utility of unescorted active travel\n(relative to escorted active)"), 12), "na", "na")) |>
  mutate(model = "Cross-nested")



results <- rbind(results_no_nest, results_cross_nest) |>
  filter(variable != "intercept" &
           variable != "alpha_active" &
           variable != "mu_active" &
           variable != "mu_parent") |>
  mutate(low = Value - 1.96*`Rob. Std err`,
         hi = Value + 1.96*`Rob. Std err`) |>
  mutate(variable = factor(variable, levels = var_names_sort))

ggplot(results, aes(x=variable, y=Value, group=model, color=model)) + 
  geom_point(position=position_dodge(0.5), size = 2, shape = "-")+
  geom_errorbar(aes(ymin=low, ymax=hi), width=0.5,
                position=position_dodge(0.5)) +
  scale_y_continuous(name = "Coefficient estimate\n(with 95-percent confidence interval)") +
  scale_x_discrete(name = "Variable") +
  scale_color_manual(name = "Model nesting\nstructure",
                       values = c("black", "gray50")) +
  geom_hline(yintercept = 0, lty = "dotted", size = 0.5) +
  facet_wrap("alternative") +
  theme(axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1))

ggsave(here("figures","compare_nests.png"), 
       dpi = 600, width = 6, height = 6, units = "in")

results_cross_nest <- results_cross_nest |>
  rename(beta_cross = Value,
         SE_cross = `Rob. Std err`,
         p_cross = `Rob. p-value`) |>
  select(variable, alternative, beta_cross, SE_cross, p_cross)

results_no_nest <- results_no_nest |>
  rename(beta_unnest = Value,
         SE_unnest = `Rob. Std err`,
         p_unnest = `Rob. p-value`) |>
  select(variable, alternative, beta_unnest, SE_unnest, p_unnest)

results_compare <- inner_join(results_no_nest, results_cross_nest) |>
  mutate(higher_mag = ifelse(abs(beta_cross) > abs(beta_unnest), "Cross-nest", "No nest")) |>
  mutate(higher_SE = ifelse(SE_cross > SE_unnest, "Cross-nest", "No nest")) |>
  mutate(sig = case_when(p_cross < 0.05 & p_unnest < 0.05 & beta_cross > 0 & beta_unnest > 0 ~ "both-sig_pos",
                         p_cross < 0.05 & p_unnest < 0.05 & beta_cross < 0 & beta_unnest < 0 ~ "both-sig_neg",
                         p_cross > 0.05 & p_unnest > 0.05 ~ "no-sig",
                         p_cross < 0.05 & p_unnest > 0.05 ~ "only-cross",
                         p_cross > 0.05 & p_unnest < 0.05 ~ "only-unnest",
                         TRUE ~ "other")) |>
  mutate(z_score = abs(beta_cross - beta_unnest) / sqrt(SE_cross^2 + SE_unnest^2)) |>
  mutate(sig_dif = z_score > 1.96) 
  
results_compare |>  
  filter(higher_mag == "Cross-nest") |>
  select(variable, alternative, sig) 

results_compare |>
  filter(sig_dif) |>
  select(variable, alternative, higher_mag, sig)

