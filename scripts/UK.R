# - - - - - - - - - - - - - - - - - - - - - - - 
# UK model: load data and analyse scenarios
# - - - - - - - - - - - - - - - - - - - - - - - 

library(rlang)
library(stringr)
library(ini)
library(qs)

# Load requested settings from command line
argv = commandArgs(trailingOnly = TRUE);
argc = length(argv);
if (argc == 3 && str_count(argv[3], "--") == 0)
{
    option.single = as.numeric(argv[3]);
} else {
    option.single = -1;
}

# List setup of files in one print statement

param_file_search = grep('--parameters*', argv, value = TRUE)   # Find location of parameters file
settings_file_search = grep('--settings*', argv, value = TRUE)  # Find location of settings file
covid_uk_search = grep('--coviduk*', argv, value = TRUE)  # Point to location of repository (if not default)
dump_params = grep('--dump', argv, value = FALSE)               # Dump parameters prior to run and exit (for testing)
contact_matrices_file_search = grep('--contact-matrices*', argv, value = TRUE)  # Find location of contact matrix data

dump_params = length(dump_params) > 0

if(length(covid_uk_search) > 0)
{
	covid_uk_path = strsplit(covid_uk_search, split = '=')[[1]][[2]];
} else {
	covid_uk_path = getwd();
}

if(length(param_file_search) > 0)
{
	parameter_file = strsplit(param_file_search, split = '=')[[1]][[2]];
} else {
	parameter_file = file.path(covid_uk_path, 'configuration', 'parameters.ini');
}

if(length(settings_file_search) > 0)
{
	settings_file = strsplit(settings_file_search, split = '=')[[1]][[2]];
} else {
	settings_file = file.path(covid_uk_path, 'configuration', 'settings.ini');
}

if(length(contact_matrices_file_search) > 0)
{
	contact_matrices_file = strsplit(contact_matrices_file_search, split = '=')[[1]][[2]];
} else {
	contact_matrices_file = file.path(covid_uk_path, 'data', 'all_matrices.rds');
}

options_print_str = paste("COVID-UK Path: ", covid_uk_path)
options_print_str = c(options_print_str,paste("Using parameters From: ",parameter_file))
options_print_str = c(options_print_str, paste("Using settings From: ",settings_file))
options_print_str = c(options_print_str, paste("Reading Contact Matrices From: ", contact_matrices_file))

config_params   = read.ini(parameter_file)
config_settings = read.ini(settings_file)
cm_matrices     = readRDS(contact_matrices_file);

set.seed(as.numeric(config_params$seed$value));

# covidm options
cm_path = file.path(covid_uk_path, "covidm");
source(file.path(cm_path, "R", "covidm.R"))


analysis = as.numeric(argv[1]);
n_runs = as.numeric(argv[2]);

analysis = 1
n_runs = 1

# Set path
# Set this path to the base directory of the repository.
# NOTE: Run from repository

# build parameters for entire UK, for setting R0.

uk_level0_key = cm_uk_locations("UK", 0)
n_age_groups  = nrow(cm_matrices[[uk_level0_key]][[1]])

parametersUK1 = cm_parameters_SEI3R(uk_level0_key, 
				    fIp  = rep(as.numeric(config_params$fIp$factor), n_age_groups),
				    fIa  = rep(as.numeric(config_params$fIa$factor), n_age_groups),
				    fIs  = rep(as.numeric(config_params$fIs$factor), n_age_groups),
				    u    = rep(as.numeric(config_params$u$factor), n_age_groups),
				    y    = rep(as.numeric(config_params$y$factor), n_age_groups),
				    tau  = rep(as.numeric(config_params$tau$factor), n_age_groups),
				    rho  = rep(as.numeric(config_params$rho$factor), n_age_groups),
                                    dE   = cm_delay_gamma(as.numeric(config_params$dE$mu), as.numeric(config_params$dE$shape), t_max = as.numeric(config_params$time$max), t_step = as.numeric(config_params$time$step))$p,
                                    dIp  = cm_delay_gamma(as.numeric(config_params$dIp$mu), as.numeric(config_params$dIp$shape), t_max = as.numeric(config_params$time$max), t_step = as.numeric(config_params$time$step))$p,
                                    dIs  = cm_delay_gamma(as.numeric(config_params$dIs$mu), as.numeric(config_params$dIs$shape), t_max = as.numeric(config_params$time$max), t_step = as.numeric(config_params$time$step))$p,
                                    dIa  = cm_delay_gamma(as.numeric(config_params$dIa$mu), as.numeric(config_params$dIa$shape), t_max = as.numeric(config_params$time$max), t_step = as.numeric(config_params$time$step))$p,
                                    deterministic = toupper(config_settings$deterministic$isTrue) == "TRUE");

# build parameters for regions of UK, down to the county level (level 3).
locations = cm_uk_locations("UK", 3);
n_age_groups  = nrow(cm_matrices[locations][[1]][[1]])
parameters = cm_parameters_SEI3R(locations, date_start = "2020-01-29", date_end = "2021-12-31",
				 fIp  = rep(as.numeric(config_params$fIp$factor), n_age_groups),
				 fIa  = rep(as.numeric(config_params$fIa$factor), n_age_groups),
				 fIs  = rep(as.numeric(config_params$fIs$factor), n_age_groups),
				 u    = rep(as.numeric(config_params$u$factor), n_age_groups),
				 y    = rep(as.numeric(config_params$y$factor), n_age_groups),
				 tau  = rep(as.numeric(config_params$tau$factor), n_age_groups),
				 rho  = rep(as.numeric(config_params$rho$factor), n_age_groups),
                                 dE  = cm_delay_gamma(as.numeric(config_params$dE$mu), as.numeric(config_params$dE$shape), t_max = as.numeric(config_params$time$max), t_step = as.numeric(config_params$time$step))$p,  # 6.5 day serial interval.
                                 dIp  = cm_delay_gamma(as.numeric(config_params$dIp$mu), as.numeric(config_params$dIp$shape), t_max = as.numeric(config_params$time$max), t_step = as.numeric(config_params$time$step))$p, # 1.5 days w/o symptoms
                                 dIs  = cm_delay_gamma(as.numeric(config_params$dIs$mu), as.numeric(config_params$dIs$shape), t_max = as.numeric(config_params$time$max), t_step = as.numeric(config_params$time$step))$p, # 5 days total of infectiousness
                                 dIa  = cm_delay_gamma(as.numeric(config_params$dIa$mu), as.numeric(config_params$dIa$shape), t_max = as.numeric(config_params$time$max), t_step = as.numeric(config_params$time$step))$p, # 5 days total of infectiousness here as well.
                                 deterministic = toupper(config_settings$deterministic$isTrue) == "TRUE");

if(dump_params)
{
    output_file_country = file.path(covid_uk_path, "output", paste0("params-UK-", gsub(" ", "_", gsub(":","",Sys.time())), ".pars"))
    dput(parametersUK1$pop, file=output_file_country)
    output_file_region = file.path(covid_uk_path, "output", paste0("params-Regional-stage1-", gsub(" ", "_", gsub(":","",Sys.time())), ".pars"))
    dput(parameters$pop, file=output_file_region)
    message(paste0("UK params saved to '", output_file_country,"\n"))
    message(paste0("Regional params saved to '", output_file_region,"\n"))
}

# Split off the elderly (70+, age groups 15 and 16) so their contact matrices can be manipulated separately
parameters = cm_split_matrices_ex_in(parameters, 15);

# Create additional matrix for child-elderly contacts
for (j in seq_along(parameters$pop))
{
  # Recover home/other contact matrix
  mat_ref = parameters$pop[[j]]$matrices[[1]] + parameters$pop[[j]]$matrices[[4]] + 
    parameters$pop[[j]]$matrices[[5]] + parameters$pop[[j]]$matrices[[8]];
  
  gran = 5/7; # adjustment for weekdays only.
  N = nrow(mat_ref);
  popsize = parameters$pop[[j]]$size;
  mat = matrix(0, ncol = N, nrow = N);
  
  # Add child-grandparent contacts: under 15s to 55+s
  if(analysis == 4)
  {
      for (a in 1:3) {
        dist = c(rep(0, 10 + a), mat_ref[a, (11 + a):N]);
        dist = dist/sum(dist);
        mat[a, ] = mat[a, ] + gran * dist;
        mat[, a] = mat[, a] + (gran * dist) * (popsize[a] / popsize);
      }
  } 
  # Add child-grandparent contact matrix to population
  parameters$pop[[j]]$matrices$gran = mat;
  parameters$pop[[j]]$contact = c(parameters$pop[[j]]$contact, 0);
}

# Health burden processes
health_burden_process_data = file.path(covid_uk_path, "data", "health_burden_processes.csv")
options_print_str = c(options_print_str,paste('Reading Health Burden Processes From:', health_burden_process_data))
probs = fread(file=health_burden_process_data)


reformat = function(P)
{
  # 70-74,3388.488  75-79,2442.147  80-84,1736.567  85-89,1077.555  90-94,490.577  95-99,130.083  100+,15.834
  x = c(P[1:7], weighted.mean(c(P[8], P[9]), c(3388.488 + 2442.147, 1736.567 + 1077.555 + 490.577 + 130.083 + 15.834)));
  return (rep(x, each = 2))
}

P.icu_symp     = reformat(probs[, Prop_symp_hospitalised * Prop_hospitalised_critical]);
P.nonicu_symp  = reformat(probs[, Prop_symp_hospitalised * (1 - Prop_hospitalised_critical)]);
P.death_icu    = reformat(probs[, Prop_critical_fatal]);
P.death_nonicu = reformat(probs[, Prop_noncritical_fatal]);
hfr = probs[, Prop_noncritical_fatal / Prop_symp_hospitalised]

burden_processes = list(
  list(source = "Ip", type = "multinomial", names = c("to_icu", "to_nonicu", "null"), report = c("", "", ""),
       prob = matrix(c(P.icu_symp, P.nonicu_symp, 1 - P.icu_symp - P.nonicu_symp), nrow = 3, ncol = 16, byrow = T),
       delays = matrix(c(cm_delay_gamma(7, 7, 60, 0.25)$p, cm_delay_gamma(7, 7, 60, 0.25)$p, cm_delay_skip(60, 0.25)$p), nrow = 3, byrow = T)),
  
  list(source = "to_icu", type = "multinomial", names = "icu", report = "p",
       prob = matrix(1, nrow = 1, ncol = 16, byrow = T),
       delays = matrix(cm_delay_gamma(10, 10, 60, 0.25)$p, nrow = 1, byrow = T)),
  
  list(source = "to_nonicu", type = "multinomial", names = "nonicu", report = "p",
       prob = matrix(1, nrow = 1, ncol = 16, byrow = T),
       delays = matrix(cm_delay_gamma(8, 8, 60, 0.25)$p, nrow = 1, byrow = T)),
  
  list(source = "Ip", type = "multinomial", names = c("death", "null"), report = c("o", ""),
       prob = matrix(c(P.death_nonicu, 1 - P.death_nonicu), nrow = 2, ncol = 16, byrow = T),
       delays = matrix(c(cm_delay_gamma(22, 22, 60, 0.25)$p, cm_delay_skip(60, 0.25)$p), nrow = 2, byrow = T))
)
parameters$processes = burden_processes

clt_i = 1;
clt_n = 0;

# Observer for lockdown scenarios
observer_lockdown = function(lockdown_trigger) function(time, dynamics)
{
  # Get current icu prevalence
  icu_prevalence = dynamics[t == time, sum(icu_p)];
  
  # Determine lockdown trigger
  trigger = lockdown_trigger;
  
  # If ICU prevalence exceeds a threshold, turn on lockdown
  if (icu_prevalence >= trigger) {
    return (list(csv = paste(time, "trace_lockdown", "All", 2, sep = ","),
                 changes = list(contact_lowerto = c(1, 0.1, 0.1, 0.1,  1, 0.1, 0.1, 0.1,  1))));
  } else  {
    return (list(csv = paste(time, "trace_lockdown", "All", 1, sep = ","),
                 changes = list(contact_lowerto = c(1, 1, 1, 1, 1, 1, 1, 1, 1))));
  }
  return (list(csv = paste(time, "trace_lockdown", "All", 1, sep = ",")))
}

# Load age-varying symptomatic rate
age_var_symptom_rates = file.path(covid_uk_path, "data", "2-linelist_symp_fit_fIa0.5.qs")
options_print_str = c(options_print_str,paste("Loading Age-Varying Symptomatic Rate From:", age_var_symptom_rates))
covid_scenario = qread(age_var_symptom_rates);

# Identify London boroughs for early seeding, and regions of each country for time courses
london = cm_structure_UK[match(str_sub(locations, 6), Name), Geography1 %like% "London"]
england = cm_structure_UK[match(str_sub(locations, 6), Name), Code %like% "^E" & !(Geography1 %like% "London")]
wales = cm_structure_UK[match(str_sub(locations, 6), Name), Code %like% "^W"]
scotland = cm_structure_UK[match(str_sub(locations, 6), Name), Code %like% "^S"]
nireland = cm_structure_UK[match(str_sub(locations, 6), Name), Code %like% "^N"]
westmid = cm_structure_UK[match(str_sub(locations, 6), Name), Name == "West Midlands (Met County)"]
cumbria = cm_structure_UK[match(str_sub(locations, 6), Name), Name == "Cumbria"]


add_totals = function(run, totals)
{
  regions = run$dynamics[, unique(population)];
  
  # totals by age
  totals0 = run$dynamics[, .(total = sum(value)), by = .(scenario, run, compartment, group)];
  return (rbind(totals, totals0))
}

add_dynamics = function(run, dynamics, iv)
{
  regions = run$dynamics[, unique(population)];
  
  interv = data.table(scenario = run$dynamics$scenario[1], run = run$dynamics$run[1], t = unique(run$dynamics$t), 
                      compartment = "trace_school", region = "All", value = unlist(iv$trace_school));
  
  if (!is.null(iv$trace_intervention)) {
    interv = rbind(interv,
                   data.table(scenario = run$dynamics$scenario[1], run = run$dynamics$run[1], t = unique(run$dynamics$t), 
                              compartment = "trace_intervention", region = "All", value = unlist(iv$trace_intervention)));
  } else {
    interv = rbind(interv,
                   data.table(scenario = run$dynamics$scenario[1], run = run$dynamics$run[1], t = unique(run$dynamics$t), 
                              compartment = "trace_intervention", region = "All", value = 1));
  }
  
  csvlines = NULL;
  if (nchar(run$csv[[1]]) > 0) {
    csvlines = fread(run$csv[[1]], header = F);
    csvlines = cbind(run$dynamics$scenario[1], run$dynamics$run[1], csvlines);
    names(csvlines) = c("scenario", "run", "t", "compartment", "region", "value");
    csvlines = unique(csvlines);
  }
  
  # time courses
  return (rbind(dynamics,
                run$dynamics[population %in% locations[westmid],  .(region = "West Midlands",    value = sum(value)), by = .(scenario, run, t, compartment)],
                run$dynamics[population %in% locations[cumbria],  .(region = "Cumbria",          value = sum(value)), by = .(scenario, run, t, compartment)],
                run$dynamics[population %in% locations[london],   .(region = "London",           value = sum(value)), by = .(scenario, run, t, compartment)],
                run$dynamics[population %in% locations[england],  .(region = "England",          value = sum(value)), by = .(scenario, run, t, compartment)],
                run$dynamics[population %in% locations[wales],    .(region = "Wales",            value = sum(value)), by = .(scenario, run, t, compartment)],
                run$dynamics[population %in% locations[scotland], .(region = "Scotland",         value = sum(value)), by = .(scenario, run, t, compartment)],
                run$dynamics[population %in% locations[nireland], .(region = "Northern Ireland", value = sum(value)), by = .(scenario, run, t, compartment)],
                run$dynamics[,                                    .(region = "United Kingdom",   value = sum(value)), by = .(scenario, run, t, compartment)],
                interv,
                csvlines
  ))
}

#############
# MAIN CODE #
#############

# Define school terms, base versus intervention (both same here)
school_terms_base_file = file.path(covid_uk_path, "data", "school_terms_base.csv")
options_print_str = c(options_print_str,paste("Reading School Terms Base Data From:", school_terms_base_file))
schools_terms_base_df = read.csv(school_terms_base_file)

school_close_b  = schools_terms_base_df[, 1]
school_reopen_b = schools_terms_base_df[, 2]

if (analysis == 1) {
  
  school_close_i  = school_close_b
  school_reopen_i = school_reopen_b
  
  # Define interventions to be used
  interventions = list(
    `School Closures`   = list(contact = c(1.0, 1.0, 0.0, 1.0,  1.0, 1.0, 0.0, 1.0,  0)),
    `Social Distancing` = list(contact = c(1.0, 0.5, 1.0, 0.5,  1.0, 0.5, 1.0, 0.5,  0)),
    `Elderly Shielding` = list(contact = c(1.0, 1.0, 1.0, 1.0,  1.0, 0.25, 1.0, 0.25,  0)),
    `Self-Isolation`    = list(fIs = rep(0.65, 16)),
    `Combination`       = list(contact = c(1.0, 0.5, 0.0, 0.5,  1.0, 0.25, 0.0, 0.25,  0), fIs = rep(0.65, 16))
  );
  
  # Set options
  option.trigger = "national";
  option.duration = 7 * 12;
  option.lockdown = NA;
  option.intervention_shift = 0;
} else if (analysis == 2.1) {
  
  # Define interventions to be used
  interventions = list(
    `Combination`       = list(contact = c(1.0, 0.5, 0.0, 0.5,  1.0, 0.25, 0.0, 0.25,  0), fIs = rep(0.65, 16))
  );

  school_close_i  = school_close_b
  school_reopen_i = school_reopen_b
  
  # Set options
  option.trigger = "national";
  option.duration = 7 * 12;
  option.lockdown = NA;
  option.intervention_shift = c(0, 14, 28, 56);
} else if (analysis == 2.2) {
  
  # Define interventions to be used
  interventions = list(
    `Combination`       = list(contact = c(1.0, 0.5, 0.0, 0.5,  1.0, 0.25, 0.0, 0.25,  0), fIs = rep(0.65, 16))
  );
  
  # Set options
  option.trigger = "local";
  option.duration = 7 * 12;
  option.lockdown = NA;
  option.intervention_shift = c(0, 14, 28, 56);
} else if (analysis == 3) {
  # Read in school terms with interventions
  school_terms_intervention_file = file.path(covid_uk_path, "data", "school_terms_intervention.csv")
  options_print_str = c(options_print_str,paste("Reading School Terms Intervention Data From:", school_terms_intervention_file))
  schools_terms_intervention_df = read.csv(school_terms_base_file)
  school_close_i  = schools_terms_intervention_df[, 1]
  school_reopen_i = schools_terms_intervention_df[, 2]
  
  # Define interventions to be used
  interventions = list(
    `Intensive Interventions` = list(contact = c(1, 0.655, 1, 0.59155,  1, 0.25, 1, 0.157375,  0), fIs = rep(0.65, 16))
  );
  
  # Set options
  option.trigger = "2020-03-17";
  option.duration = 364;
  #option.lockdown = c(NA, 1000, 2000, 5000);
  option.lockdown = c(1000)
  option.intervention_shift = 0;
} else if (analysis == 4) {
  
  # Define school terms, base versus intervention (both same here)
  school_close_i  = school_close_b
  school_reopen_i = school_reopen_b
  
  # Define interventions to be used
  interventions = list(
    `Intensive`                    = list(contact = c(1, 0.655, 1, 0.59155,  1, 0.25, 1, 0.157375,  0.0), fIs = rep(0.65, 16)),
    `Intensive + School`           = list(contact = c(1, 0.655, 0, 0.59155,  1, 0.25, 0, 0.157375,  0.0), fIs = rep(0.65, 16)),
    `Intensive + School + G20`     = list(contact = c(1, 0.655, 0, 0.59155,  1, 0.25, 0, 0.157375,  0.2), fIs = rep(0.65, 16)),
    `Intensive + School + G50`     = list(contact = c(1, 0.655, 0, 0.59155,  1, 0.25, 0, 0.157375,  0.5), fIs = rep(0.65, 16)),
    `Intensive + School + G100`    = list(contact = c(1, 0.655, 0, 0.59155,  1, 0.25, 0, 0.157375,  1.0), fIs = rep(0.65, 16))
  );
  
  # Set options
  option.trigger = "2020-03-17";
  option.duration = 125;
  option.lockdown = NA;
  option.intervention_shift = 0;
  parameters$time1 = "2020-07-20";
} else if (analysis == 6) {

  # Define school terms, base versus intervention (both same here)
  school_close_i  = school_close_b
  school_reopen_i = school_reopen_b
  
  # Define interventions to be used
  interventions = list(
    `Background`               = list(contact = c(1, 1, 0, 1,          1, 0.25, 0, 0.25,  0), fIs = rep(0.65, 16)),
    `Background + 0% Sports`   = list(contact = c(1, 1, 0, 1 - 0.0041, 1, 0.25, 0, 0.25,  0), fIs = rep(0.65, 16)),
    `Background + 25% Leisure` = list(contact = c(1, 1, 0, 1 - 0.362,  1, 0.25, 0, 0.25,  0), fIs = rep(0.65, 16))
  );
  
  # Set options
  option.trigger = "2020-03-17";
  option.duration = 168;
  option.lockdown = NA;
  option.intervention_shift = 0;
  parameters$time1 = "2020-09-01";
}

# Pick R0s 

R0s = rnorm(n_runs, mean = 2.675739, sd = 0.5719293)

# Do runs
dynamics = data.table()
totals = data.table()
print(Sys.time())

output_file_name = file.path(covid_uk_path, paste0(analysis, "-dynamics", ifelse(option.single > 0, option.single, ""), ".qs"))
options_print_str = c(options_print_str,paste("Output File:", output_file_name))
print(options_print_str)

if (option.single < 0) {
    run_set = 1:n_runs;
} else {
    run_set = option.single;
}

for (r in run_set) {
  cat(paste0(r, ": R0 = ", R0s[r], "\n"));
  
  # 1. Pick age-varying symptomatic rate
  covy = unname(unlist(covid_scenario[sample.int(nrow(covid_scenario), 1), f_00:f_70]));
  covy = rep(covy, each = 2);
  
  # 2. Calculate R0 adjustment needed
  parametersUK1$pop[[1]]$y = covy;
  u_adj = R0s[r] / cm_calc_R0(parametersUK1, 1);
  
  # 3. Pick seeding times
  seed_start = ifelse(london, sample(0:6, length(london), replace = T), sample(0:20, length(london), replace = T));
  
  # 4. Do base model
  
  # 4a. Set parameters
  params = duplicate(parameters);
  for (j in seq_along(params$pop)) {
    params$pop[[j]]$u = params$pop[[j]]$u * u_adj;
    params$pop[[j]]$y = covy;
    params$pop[[j]]$seed_times = rep(seed_start[j] + 0:27, each = 2);
    params$pop[[j]]$dist_seed_ages = cm_age_coefficients(25, 50, 5 * 0:16);
  }
  
  # CALCULATE IMPACT ON R0
  if (analysis == 5) {
    interventions = list(
      `Base`                      = list(),
      `School Closures`           = list(contact = c(1.0, 1.0, 0.0, 1.0,  1.0, 1.0, 0.0, 1.0,  0)),
      `Social Distancing`         = list(contact = c(1.0, 0.5, 1.0, 0.5,  1.0, 0.5, 1.0, 0.5,  0)),
      `Elderly Shielding`         = list(contact = c(1.0, 1.0, 1.0, 1.0,  1.0, 0.25, 1.0, 0.25,  0)),
      `Self-Isolation`            = list(fIs = rep(0.65, 16)),
      `Combination`               = list(contact = c(1.0, 0.5, 0.0, 0.5,  1.0, 0.25, 0.0, 0.25,  0), fIs = rep(0.65, 16)),
      `Intensive, schools open`   = list(contact = c(1, 0.655, 1, 0.59155,  1, 0.25, 1, 0.157375,  0), fIs = rep(0.65, 16)),
      `Intensive, schools closed` = list(contact = c(1, 0.655, 0, 0.59155,  1, 0.25, 0, 0.157375,  0), fIs = rep(0.65, 16)),
      `Lockdown`                  = list(contact = c(1, 0.1, 0.1, 0.1,  1, 0.1, 0.1, 0.1,  0), fIs = rep(0.65, 16))
    );
    
    for (i in seq_along(interventions))
    {
      iR0s = rep(0, length(params$pop));
      iweights = rep(0, length(params$pop));
      for (j in seq_along(params$pop))
      {
        for (k in seq_along(interventions[[i]]))
        {
          params$pop[[j]][[names(interventions[[i]])[k]]] = interventions[[i]][[k]];
        }
        iR0s[j] = cm_calc_R0(params, j);
        iweights[j] = sum(params$pop[[j]]$size);
      }
      
      weighted_R0 = weighted.mean(iR0s, iweights);
      dynamics = rbind(dynamics, data.table(run = r, scenario = names(interventions)[i], R0 = weighted_R0));
  
    }
    
    next;
  }
  
  # 4b. Set school terms
  iv = cm_iv_build(params)
  cm_iv_set(iv, school_close_b, school_reopen_b, contact = c(1, 1, 0, 1,  1, 1, 0, 1,  1), trace_school = 2);
  params = cm_iv_apply(params, iv);

  if(dump_params)
  {
    output_file = file.path(covid_uk_path, "output", paste0("params-Regional-stage2-", gsub(" ", "_", gsub(":","",Sys.time())), ".pars"))
    dput(params, file=output_file)
    message(paste0("Regional params saved to '", output_file,"' aborting"))
    quit()
  }
  
  # 4c. Run model
  run = cm_simulate(params, 1, r);
  run$dynamics[, run := r];
  run$dynamics[, scenario := "Base"];
  run$dynamics[, R0 := R0s[r]];
  totals = add_totals(run, totals);
  dynamics = add_dynamics(run, dynamics, iv);
  peak_t = run$dynamics[compartment == "cases", .(total_cases = sum(value)), by = t][, t[which.max(total_cases)]];
  peak_t_bypop = run$dynamics[compartment == "cases", .(total_cases = sum(value)), by = .(t, population)][, t[which.max(total_cases)], by = population]$V1;
  
  rm(run)
  gc()
  
  # 5. Run interventions
  for (i in seq_along(interventions)) {
    for (duration in option.duration) {
      for (trigger in option.trigger) {
        for (intervention_shift in option.intervention_shift) {
          for (lockdown in option.lockdown) {
            cat(paste0(names(interventions)[i], "...\n"))
            
            # 5a. Make parameters and adjust R0
            params = duplicate(parameters);
            for (j in seq_along(params$pop)) {
              params$pop[[j]]$u = params$pop[[j]]$u * u_adj;
              params$pop[[j]]$y = covy;
              if (!is.na(lockdown)) {
                params$pop[[j]]$observer = observer_lockdown(lockdown);
              }
            }
            
            # 5b. Set interventions
            if (trigger == "national") {
              intervention_start = peak_t - duration / 2 + intervention_shift;
            } else if (trigger == "local") {
              intervention_start = peak_t_bypop - duration / 2 + intervention_shift;
            } else {
              intervention_start = as.numeric(ymd(trigger) - ymd(params$date0));
            }
            
            if (trigger == "local") {
              # Trigger interventions to one population at a time.
              for (pi in seq_along(params$pop)) {
                ymd_start = ymd(params$date0) + intervention_start[pi];
                ymd_end = ymd_start + duration - 1;
                iv = cm_iv_build(params)
                cm_iv_set(iv, school_close_i, school_reopen_i, contact = c(1, 1, 0, 1,  1, 1, 0, 1,  1), trace_school = 2);
                cm_iv_set(iv, ymd_start, ymd_end, interventions[[i]]);
                cm_iv_set(iv, ymd_start, ymd_end, trace_intervention = 2);
                params = cm_iv_apply(params, iv, pi);
              }
            } else {
	      # Trigger interventions all at once.
              ymd_start = ymd(params$date0) + intervention_start;
              ymd_end = ymd_start + duration - 1;
              iv = cm_iv_build(params)
              cm_iv_set(iv, school_close_i, school_reopen_i, contact = c(1, 1, 0, 1,  1, 1, 0, 1,  1), trace_school = 2);
              cm_iv_set(iv, ymd_start, ymd_end, interventions[[i]]);
              cm_iv_set(iv, ymd_start, ymd_end, trace_intervention = 2);
              params = cm_iv_apply(params, iv);
            }
            
            # 5c. Run model
            run = cm_simulate(params, 1, r);
            
            tag = "";
            if (length(option.duration) > 1)            { tag = paste0(tag, " ", duration + 1, " day"); }
            if (length(option.lockdown) > 1)            { tag = paste0(tag, " ", ifelse(lockdown >= 0, lockdown, "variable"), " lockdown"); }
            if (length(option.trigger) > 1)             { tag = paste0(tag, " ", trigger, " trigger"); }
            if (length(option.intervention_shift) > 1)  { tag = paste0(tag, " ", intervention_shift, " shift"); }
            
            run$dynamics[, run := r];
            run$dynamics[, scenario := paste0(names(interventions)[i], tag)];
            run$dynamics[, R0 := R0s[r]];
            totals = add_totals(run, totals);
            dynamics = add_dynamics(run, dynamics, iv);
            
            rm(run)
            gc()
          }
        }
      }
    }
  }
}
cm_save(totals, file.path(covid_uk_path, paste0(analysis, "-totals", ifelse(option.single > 0, option.single, ""), ".qs")));
cm_save(dynamics, file.path(covid_uk_path, paste0(analysis, "-dynamics", ifelse(option.single > 0, option.single, ""), ".qs")));
print(Sys.time())
