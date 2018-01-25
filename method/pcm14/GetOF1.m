function [ OF ] = GetOF( feedback,num )
    
    ST = [];
    DT = [];
    SL = [];
    DL = [];
    SimilarTorse = {};
    DissimilarTorse = {};
    SimilarLeg = {};
    DissimilarLeg = {};
    
    CSimilarTorse = {};
    CDissimilarTorse = {};
    CSimilarLeg = {};
    CDissimilarLeg = {};
 for i =1:size(feedback.feedback_details,2)
     if feedback.feedback_details{1,i}.box_type(1,1) == 1
         CSimilarTorse{size(CSimilarTorse,1)+1,1} = feedback.feedback_details{1,i}.gallery_name;
         ST(size(CSimilarTorse,1),1) = feedback.feedback_details{1,i}.box_conf(1,1);
     end
     if feedback.feedback_details{1,i}.box_type(1,1) == -1
         CDissimilarTorse{size(CDissimilarTorse,1)+1,1} = feedback.feedback_details{1,i}.gallery_name;
         DT(size(CDissimilarTorse,1),1) = feedback.feedback_details{1,i}.box_conf(1,1);
     end
     if feedback.feedback_details{1,i}.box_type(2,1) == 1
         CSimilarLeg{size(CSimilarLeg,1)+1,1} = feedback.feedback_details{1,i}.gallery_name;
         SL(size(CSimilarLeg,1),1) = feedback.feedback_details{1,i}.box_conf(2,1);
     end
     if feedback.feedback_details{1,i}.box_type(2,1) == -1
         CDissimilarLeg{size(CDissimilarLeg,1)+1,1} = feedback.feedback_details{1,i}.gallery_name;
         DL(size(CDissimilarLeg,1),1) = feedback.feedback_details{1,i}.box_conf(2,1);
     end
 end
     [~,Ind1] = sort(ST,'descend');
     [~,Ind2] = sort(DT,'descend');
     [~,Ind3] = sort(SL,'descend');
     [~,Ind4] = sort(DL,'descend');
     for j =1:num
         SimilarTorse{j,1} = CSimilarTorse{Ind1(j,1),1};
         DissimilarTorse{j,1} = CDissimilarTorse{Ind2(j,1),1};
         SimilarLeg{j,1} = CSimilarLeg{Ind3(j,1),1};
         DissimilarLeg{j,1} = CDissimilarLeg{Ind4(j,1),1};
     end
     for nn=1:size(SimilarTorse,1)
         SimilarTorse{nn,2} = GetIndex(SimilarTorse{nn,1});
         DissimilarTorse{nn,2} = GetIndex(DissimilarTorse{nn,1});
         SimilarLeg{nn,2} = GetIndex(SimilarLeg{nn,1});
         DissimilarLeg{nn,2} = GetIndex(DissimilarLeg{nn,1});
     end
    OF.SimilarTorse = SimilarTorse;
    OF.DissimilarTorse = DissimilarTorse;
    OF.SimilarLeg = SimilarLeg;
    OF.DissimilarLeg = DissimilarLeg;
       
     
     
     
     