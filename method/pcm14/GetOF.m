function [OF, ave_conf] = GetOF(feedback,num,iProbe,include_groundtruth_in_the_first_page_flag)
    
    load('Aford_20');
    load('IsGroundTruth20');
    load('All_Name.mat');
    SimilarTorseConf = [];
    DissimilarTorseConf = [];
    SimilarLegConf = [];
    DissimilarLegConf = [];
    
    SimilarTorse = {};
    DissimilarTorse = {};
    SimilarLeg = {};
    DissimilarLeg = {};
    LOG ={};
    gt_hit_num = 0;
    
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

    RST(1,:) = randperm(size(CSimilarTorse,1));
    RDT(1,:) = randperm(size(CDissimilarTorse,1));
    RSL(1,:) = randperm(size(CSimilarLeg,1));
    RDL(1,:) = randperm(size(CDissimilarLeg,1));
     
         

     for j =1:num
         SimilarTorse{j,1} = CSimilarTorse{RST(1,j),1};
         DissimilarTorse{j,1} = CDissimilarTorse{RDT(1,j),1};
         SimilarLeg{j,1} = CSimilarLeg{RSL(1,j),1};
         DissimilarLeg{j,1} = CDissimilarLeg{RDL(1,j),1};
     end
     
     SimilarTorseConf = mean(ST(RST(1,1:num)));
     DissimilarTorseConf = mean(DT(RDT(1,1:num)));
     SimilarLegConf = mean(SL(RSL(1,1:num)));
     DissimilarLegConf = mean(DL(RDL(1,1:num)));
     
     if include_groundtruth_in_the_first_page_flag
         if IsGroundTruth(1,iProbe)%上半身zai qian 20
             if Str_Exist(Picture{iProbe,2}(1:end-4),CSimilarTorse)
                 if ~Str_Exist(Picture{iProbe,2}(1:end-4),SimilarTorse)%前num未选中v
                 SimilarTorse{1,1} = Picture{iProbe,2}(1:end-4);
                 end

             else
                   SimilarTorse{1,1} = Picture{iProbe,2}(1:end-4);
             end
          end

         if IsGroundTruth(1,iProbe)%xia半身zai qian 20
             if Str_Exist(Picture{iProbe,2}(1:end-4),CSimilarLeg)%前num未选中
                 if ~Str_Exist(Picture{iProbe,2}(1:end-4),SimilarLeg)
                 SimilarLeg{1,1} = Picture{iProbe,2}(1:end-4);
                 end
             else

               SimilarLeg{1,1} = Picture{iProbe,2}(1:end-4);
             end
         end
     end

         
     for nn=1:size(SimilarTorse,1)
         SimilarTorse{nn,2} = GetIndex(SimilarTorse{nn,1});
         DissimilarTorse{nn,2} = GetIndex(DissimilarTorse{nn,1});
         SimilarLeg{nn,2} = GetIndex(SimilarLeg{nn,1});
         DissimilarLeg{nn,2} = GetIndex(DissimilarLeg{nn,1});
     end
     
    if iProbe==SimilarTorse{nn,2}
        SimilarTorseConf = 1;
    end
    
    if iProbe==DissimilarTorse{nn,2}
        DissimilarTorseConf = 1;
    end
    
    if iProbe==SimilarLeg{nn,2}
        SimilarLegConf = 1;
    end
    
    if iProbe==DissimilarLeg{nn,2}
        DissimilarLegConf = 1;
    end
    
    ave_conf = [SimilarTorseConf; DissimilarTorseConf; SimilarLegConf; DissimilarLegConf];
    
    OF.SimilarTorse = SimilarTorse;
    OF.DissimilarTorse = DissimilarTorse;
    OF.SimilarLeg = SimilarLeg;
    OF.DissimilarLeg = DissimilarLeg;
       
     
     