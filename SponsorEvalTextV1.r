
library("tidyverse")
library("openxlsx")    # library("readxl") # this is the tidyverse installed package
library("scales")
library("lubridate")
library("rstudioapi")
library("jsonlite")
library("knitr")
library("rmarkdown")
library("kableExtra")


############# This is a cool way to get team data, but canvas names can (AND DO) change, so it might be better to just keep 
############# passing around the GroupsWithNames.csv file

######### NOTE: if there is MORE than ONE group category, call4groups is a vector ... pick the right one! ##################

# set the Canvas Class ID
class_id <- "63712"       ## MAE151B_Sp24

# set some strings for the fromJSON calls
token <- "4407~cV0DPpTSmVsjyrYteGHINIXvE76TD7RTy750ASCHFUfj6yqMONUXOqlgWsoPkIXt" #Authorization token. Set this up in your Canvas profile
canvas_base <- "https://canvas.eee.uci.edu/api/v1/"
cats_call <- paste0("/group_categories?access_token=",token)
groups_call <- paste0("/groups?per_page=100&access_token=",token)
users_call <- paste0("/users?per_page=100&access_token=",token)

#now get ids for each group category ########## ONLY ONE should exist ################
call4cats <- paste0(canvas_base,"courses/",class_id,cats_call)
categorydata <- fromJSON(call4cats)


#now find all the ids and names of each group/team in each category    ############## ONLY ONE Category!!! ##########
call4groups <- paste0(canvas_base,"group_categories/",categorydata$id,groups_call)
# groupdata <- fromJSON(call4groups)
groupdata <- fromJSON(call4groups[2])              # calling the 2nd element of the vector here!!!!
group_info <- tibble(GroupID=groupdata$id,GroupName=groupdata$name,MemberCnt=groupdata$members_count) %>% 
  filter(MemberCnt>0)    # drop any groups that have zero members

# now get set the call string for each group/team and then loop through and get data into "teamdata"
call4users <- paste0(canvas_base,"groups/",group_info$GroupID,users_call)  
teamdata <- tibble(ProjectName=character(), NumMembers=numeric(), UCInetID=character(), Name=character())

#students <- tibble(Names=character())
for (i in 1:nrow(group_info)) {
  userdata <- fromJSON(call4users[i])
  teamdata <- teamdata %>% add_row(ProjectName=group_info$GroupName[i],NumMembers=group_info$MemberCnt[i],
                                   UCInetID=userdata$login_id,Name=userdata$name)
}

write.csv(teamdata, file = "GroupsWithNames.csv",row.names=FALSE)

# Data
projects <- unique(teamdata$ProjectName)
sponsors <- c("Aaron","Perry","Derek and Moses","Mike",
              "Vince","Camilo","Tryphon","Andrei","Tyler","David","Xian","Amir","Mark",
              "Sherif","Sherif","David","Mike", "Joyce and Camilo",
              "Nicholas and Tryphon","Nicholas and Tryphon","Andrei")

## Loop
for (i in 1:length(projects)){   # 2){ # 
  students <- teamdata %>% filter(ProjectName %in% projects[i])
  evaltable <- tibble("Student Names"=students$Name, "Outstanding"=NA, "Very Good"=NA, "Good"=NA,
                      "Fair"=NA, "Poor"=NA)
  evaltable <- evaltable %>% mutate(across(everything(), ~ replace(.x, is.na(.x), "")))
  rmarkdown::render(input = "SponsorEval.Rmd",
 #                   output_format = "html",
                    output_file = paste("Message_", i, ".html", sep=''), 
                    output_dir = "Docs/")
}


i <- 19


