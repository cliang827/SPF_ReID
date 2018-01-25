function [ OF ] = GetOF( feedback,num )
    OF={};
    nt = 0;
    nl = 0;
    st =0;
    sl=0;
    n=1;
    for i =1:size(feedback.feedback_details,2)
       if feedback.feedback_details{1,i}.box_type(1,1) == 1 && st<num
          st=st+1;
          OF{n}.gallery_name  = feedback.feedback_details{1,i}.gallery_name;
          OF{n}.type = 'SimilarTorse';
          n=n+1;  
       elseif feedback.feedback_details{1,i}.box_type(1,1) == -1  && nt<num
          nt=nt+1;
          OF{n}.gallery_name  = feedback.feedback_details{1,i}.gallery_name;
          OF{n}.type = 'DissimilarTorse';
          n=n+1;
       end
       
       if feedback.feedback_details{1,i}.box_type(2,1) == 1 && sl<num
          sl=sl+1;
          OF{n}.gallery_name  = feedback.feedback_details{1,i}.gallery_name;
          OF{n}.type = 'SimilarLeg';
          n=n+1;  
       elseif feedback.feedback_details{1,i}.box_type(2,1) == -1  && nl<num
          nl=nl+1;
          OF{n}.gallery_name  = feedback.feedback_details{1,i}.gallery_name;
          OF{n}.type = 'DissimilarLeg';
          n=n+1;
       end
       if n == num*4 +1
           break;
       end
    end
    nn=0;
    for i=1:size(OF,2)
        if strcmp(OF{1,i}.type,'SimilarTorse')
            nn = nn + 1;
            SimilarTorse{nn,1} =  OF{1,i}.gallery_name;
            SimilarTorse{nn,2} = GetIndex(SimilarTorse{nn,1});
        end
    end
    nn=0;
    for i=1:size(OF,2)
        if strcmp(OF{1,i}.type,'DissimilarTorse')
            nn = nn + 1;
            DissimilarTorse{nn,1} =  OF{1,i}.gallery_name;
            DissimilarTorse{nn,2} = GetIndex(DissimilarTorse{nn,1});
        end
    end
    nn=0;
    for i=1:size(OF,2)
        if strcmp(OF{1,i}.type,'SimilarLeg')
            nn = nn + 1;
            SimilarLeg{nn,1} =  OF{1,i}.gallery_name;
            SimilarLeg{nn,2} = GetIndex( SimilarLeg{nn,1});
        end
    end
    nn=0;
    for i=1:size(OF,2)
        if strcmp(OF{1,i}.type,'DissimilarLeg')
            nn = nn + 1;
            DissimilarLeg{nn,1} =  OF{1,i}.gallery_name;
            DissimilarLeg{nn,2} = GetIndex(DissimilarLeg{nn,1});
        end
    end
    clear OF;
    OF.SimilarTorse = SimilarTorse;
    OF.DissimilarTorse = DissimilarTorse;
    OF.SimilarLeg = SimilarLeg;
    OF.DissimilarLeg = DissimilarLeg;
end

