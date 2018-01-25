function Eqs = Eq_func(v, L, beta, gamma, norm_type, L_hat_plus, L_hat_minus, d_hat, vt)
% Eqs = [Eq_12; Eq_15; Eq_18; Eq_21; Eq_22];

% Eq.(12)
m = size(v,1);
L_hat = L-beta;

Eq_12_term_1 = (1-v)'*L_hat*(1-v)/(m*m);
Eq_12_term_2 = gamma*norm(v,norm_type)/m;
Eq_12 = Eq_12_term_1 - Eq_12_term_2;

% Eq.(15)
fv = v'*L_hat_plus*v/(m*m)-2*v'*d_hat/(m*m);
gv = v'*L_hat_minus*v/(m*m)+gamma*norm(v,norm_type)/m;
const_eq_13 = sum(sum(L_hat))/(m*m);    % irrelevant term from Eq.(13)->Eq.(14)
Eq_15_term_1 = fv;
Eq_15_term_2 = gv;
Eq_15 = Eq_15_term_1 - Eq_15_term_2;
% if abs(Eq_12)==0
%     assert(abs(Eq_12-(Eq_15 + const_eq_13))<1e-3);
% else
%     assert(abs(Eq_12-(Eq_15 + const_eq_13))/abs(Eq_12)<1e-3);
% end


% Eq.(20)
if norm_type== 2
    if norm(vt,norm_type)<1e-6
        partial_norm_vt = zeros(m,1);
    else
        partial_norm_vt = vt/norm(vt,norm_type);
    end
elseif norm_type == 1
    partial_norm_vt = ones(m,1);
end

% Eq.(19)
partial_g_vt = 2*L_hat_minus*vt/(m*m) + gamma*partial_norm_vt/m;

% Eq.(18)
g_vt = vt'*L_hat_minus*vt/(m*m)+gamma*norm(vt,norm_type)/m;
Eq_18_term_1 = g_vt;
Eq_18_term_2 = partial_g_vt'*(v-vt);
Eq_18 = Eq_18_term_1 + Eq_18_term_2;

% Eq.(21)
const_eq_21 = vt'*L_hat_minus*vt/(m*m)+gamma*norm(vt,norm_type)/m - ...
    vt'*(2*L_hat_minus*vt/(m*m) + gamma*partial_norm_vt/m);
Eq_21_term_1 = v'*(2*L_hat_minus*vt/(m*m) + gamma*partial_norm_vt/m);
Eq_21_term_2 = const_eq_21;
Eq_21 = Eq_21_term_1 + Eq_21_term_2;
% if abs(Eq_21)==0
%     assert(abs(Eq_18-Eq_21)<1e-3);
% else
%     assert(abs(Eq_18-Eq_21)/abs(Eq_18)<1e-3);
% end

% Eq.(22)
Eq_22_term_1 = fv;
Eq_22_term_2 = Eq_21;
Eq_22 = Eq_22_term_1 - Eq_22_term_2;

% Output
Eqs.Eq_12 = Eq_12;
Eqs.Eq_15 = Eq_15;
Eqs.Eq_18 = Eq_18;
Eqs.Eq_21 = Eq_21;
Eqs.Eq_22 = Eq_22;










