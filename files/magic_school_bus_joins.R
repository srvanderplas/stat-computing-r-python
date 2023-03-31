library(readxl)
res <- purrr::map(1:5, ~read_xlsx("data/magic_school_bus.xlsx", sheet = .))

Individual <- res[[1]]
Teacher <- res[[2]] %>%
  mutate(classID = as.numeric(classID))
Student <- res[[3]]
Class <- res[[4]]
Location <- res[[5]]

library(dplyr)
right_join(Teacher, Individual)
full_join(Teacher, Individual) %>%
  arrange(full_name)
semi_join(Teacher, Individual)

left_join(Teacher, Individual) %>%
  arrange(full_name)

inner_join(Individual, Student)

anti_join(Individual, Teacher)

semi_join(Individual, Teacher)
left_join(Individual, Teacher)


inner_join(Individual, Teacher)

Teacher %>%
  mutate(classID=as.numeric(classID)) %>%
full_join(Class, by = c("classID"="ID")) %>%
  full_join(Location, by = c("locationID"="ID"))

left_join(Class, Location, by = c("locationID" = "ID")) %>%
  full_join(Teacher, by = c("ID" = "classID"))


anti_join(Teacher, Class, by = c("classID" = "ID"))
