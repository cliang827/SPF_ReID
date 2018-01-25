FBData = '..\FBData\test_feedback\';
load('All_Name.mat');
a =[];

for iProbe = 1:316
    num=0;
     load([FBData,Picture{iProbe,1}(1:end-4),'.mat']);
    for i =1:size(feedback_info.feedback_details,2)
        if feedback_info.feedback_details{1,i}.body_part(2,1) ==2 && feedback_info.feedback_details{1,i}.box_type(2,1) == 1
        num=num+1;
        end
    end
    if num <10
        fprintf('%s,%d\n',Picture{iProbe,1},num);
    end
    
end