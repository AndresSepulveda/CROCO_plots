from numpy import shape, zeros
def u2rho_2d(var_u):
	Mp,L = shape(var_u)
	Lp = L+1
	Lm = L-1
	var_rho = zeros((Mp,Lp))
	var_rho[:,1:L] = 0.5 * (var_u[:,0:Lm] + var_u[:,1:L] )
	var_rho[:,0] = var_rho[:,1]
	var_rho[:,Lp-1] = var_rho[:,L-1]
	return var_rho

def v2rho_2d(var_v):
        M,Lp = shape(var_v)
        Mp = M+1
        Mm = M-1
        var_rho = zeros((Mp,Lp))
        var_rho[1:M,:] = 0.5 * (var_v[0:Mm,:] + var_v[1:M,:] )
        var_rho[0,:] = var_rho[1,:]
        var_rho[Mp-1,:] = var_rho[M-1,:]
        return var_rho
