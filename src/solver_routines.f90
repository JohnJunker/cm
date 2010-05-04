!> \file
!> $Id$
!> \author Chris Bradley
!> \brief This module handles all solver routines.
!>
!> \section LICENSE
!>
!> Version: MPL 1.1/GPL 2.0/LGPL 2.1
!>
!> The contents of this file are subject to the Mozilla Public License
!> Version 1.1 (the "License"); you may not use this file except in
!> compliance with the License. You may obtain a copy of the License at
!> http://www.mozilla.org/MPL/
!>
!> Software distributed under the License is distributed on an "AS IS"
!> basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
!> License for the specific language governing rights and limitations
!> under the License.
!>
!> The Original Code is OpenCMISS
!>
!> The Initial Developer of the Original Code is University of Auckland,
!> Auckland, New Zealand and University of Oxford, Oxford, United
!> Kingdom. Portions created by the University of Auckland and University
!> of Oxford are Copyright (C) 2007 by the University of Auckland and
!> the University of Oxford. All Rights Reserved.
!>
!> Contributor(s):
!>
!> Alternatively, the contents of this file may be used under the terms of
!> either the GNU General Public License Version 2 or later (the "GPL"), or
!> the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
!> in which case the provisions of the GPL or the LGPL are applicable instead
!> of those above. If you wish to allow use of your version of this file only
!> under the terms of either the GPL or the LGPL, and not to allow others to
!> use your version of this file under the terms of the MPL, indicate your
!> decision by deleting the provisions above and replace them with the notice
!> and other provisions required by the GPL or the LGPL. If you do not delete
!> the provisions above, a recipient may use your version of this file under
!> the terms of any one of the MPL, the GPL or the LGPL.
!>

!> This module handles all solver routines.
MODULE SOLVER_ROUTINES

  USE BASE_ROUTINES
  USE BOUNDARY_CONDITIONS_ROUTINES
  USE CMISS_PETSC
  USE COMP_ENVIRONMENT
  USE CONSTANTS
  USE DISTRIBUTED_MATRIX_VECTOR
  USE EQUATIONS_SET_CONSTANTS
  USE FIELD_ROUTINES
  USE KINDS
  USE INPUT_OUTPUT
  USE ISO_VARYING_STRING
  USE PROBLEM_CONSTANTS
  USE SOLVER_MAPPING_ROUTINES
  USE SOLVER_MATRICES_ROUTINES
  USE STRINGS
  USE TIMER
  USE TYPES

  IMPLICIT NONE

  PRIVATE

#include "include/petscversion.h"
 
  !Module parameters

  !> \addtogroup SOLVER_ROUTINES_SolverTypes SOLVER_ROUTINES::SolverTypes
  !> \brief The types of solver
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_LINEAR_TYPE=1 !<A linear solver \see SOLVER_ROUTINES_SolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_NONLINEAR_TYPE=2 !<A nonlinear solver  \see SOLVER_ROUTINES_SolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_TYPE=3 !<A dynamic solver \see SOLVER_ROUTINES_SolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_TYPE=4 !<A differential-algebraic equation solver \see SOLVER_ROUTINES_SolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_EIGENPROBLEM_TYPE=5 !<A eigenproblem solver \see SOLVER_ROUTINES_SolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_OPTIMISER_TYPE=6 !<An optimiser solver \see SOLVER_ROUTINES_SolverTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_SolverLibraries SOLVER_ROUTINES::SolverLibraries
  !> \brief The types of solver libraries
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_CMISS_LIBRARY=LIBRARY_CMISS_TYPE !<CMISS (internal) solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_PETSC_LIBRARY=LIBRARY_PETSC_TYPE !<PETSc solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_MUMPS_LIBRARY=LIBRARY_MUMPS_TYPE !<MUMPS solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_SUPERLU_LIBRARY=LIBRARY_SUPERLU_TYPE !<SuperLU solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_SPOOLES_LIBRARY=LIBRARY_SPOOLES_TYPE !<Spooles solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_UMFPACK_LIBRARY=LIBRARY_UMFPACK_TYPE !<UMFPACK solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_LUSOL_LIBRARY=LIBRARY_LUSOL_TYPE !<LUSOL solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ESSL_LIBRARY=LIBRARY_ESSL_TYPE !<ESSL solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_LAPACK_LIBRARY=LIBRARY_LAPACK_TYPE !<LAPACK solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_TAO_LIBRARY=LIBRARY_TAO_TYPE !<TAO solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_HYPRE_LIBRARY=LIBRARY_HYPRE_TYPE !<Hypre solver library \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
   !>@}

  !> \addtogroup SOLVER_ROUTINES_LinearSolverTypes SOLVER_ROUTINES::LinearSolverTypes
  !> \brief The types of linear solvers
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_LINEAR_DIRECT_SOLVE_TYPE=1 !<Direct linear solver type \see SOLVER_ROUTINES_LinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE=2 !<Iterative linear solver type \see SOLVER_ROUTINES_LinearSolverTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_DirectLinearSolverTypes SOLVER_ROUTINES::DirectLinearSolverTypes
  !> \brief The types of direct linear solvers
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_DIRECT_LU=1 !<LU direct linear solver \see SOLVER_ROUTINES_DirectLinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DIRECT_CHOLESKY=2 !<Cholesky direct linear solver \see SOLVER_ROUTINES_DirectLinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DIRECT_SVD=3 !<SVD direct linear solver \see SOLVER_ROUTINES_DirectLinearSolverTypes,SOLVER_ROUTINES
  !>@}
  
  !> \addtogroup SOLVER_ROUTINES_IterativeLinearSolverTypes SOLVER_ROUTINES::IterativeLinearSolverTypes
  !> \brief The types of iterative linear solvers
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_RICHARDSON=1 !<Richardson iterative solver type \see SOLVER_ROUTINES_IterativeLinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_CHEBYCHEV=2 !<Chebychev iterative solver type \see SOLVER_ROUTINES_IterativeLinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_CONJUGATE_GRADIENT=3 !<Conjugate gradient iterative solver type \see SOLVER_ROUTINES_IterativeLinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_BICONJUGATE_GRADIENT=4 !<Bi-conjugate gradient iterative solver type \see SOLVER_ROUTINES_IterativeLinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_GMRES=5 !<Generalised minimum residual iterative solver type \see SOLVER_ROUTINES_IterativeLinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_BiCGSTAB=6 !<Stabalised bi-conjugate gradient iterative solver type \see SOLVER_ROUTINES_IterativeLinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_CONJGRAD_SQUARED=7 !<Conjugate gradient squared iterative solver type \see SOLVER_ROUTINES_IterativeLinearSolverTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_IterativePreconditionerTypes SOLVER_ROUTINES::IterativePreconditionerTypes
  !> \brief The types of iterative preconditioners
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_NO_PRECONDITIONER=0 !<No preconditioner type \see SOLVER_ROUTINES_IterativePreconditionerTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_JACOBI_PRECONDITIONER=1 !<Jacobi preconditioner type \see SOLVER_ROUTINES_IterativePreconditionerTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_BLOCK_JACOBI_PRECONDITIONER=2 !<Iterative block Jacobi preconditioner type \see SOLVER_ROUTINES_IterativePreconditionerTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_SOR_PRECONDITIONER=3 !<Successive over relaxation preconditioner type \see SOLVER_ROUTINES_IterativePreconditionerTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_INCOMPLETE_CHOLESKY_PRECONDITIONER=4 !<Incomplete Cholesky preconditioner type \see SOLVER_ROUTINES_IterativePreconditionerTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_INCOMPLETE_LU_PRECONDITIONER=5 !<Incomplete LU preconditioner type \see SOLVER_ROUTINES_IterativePreconditionerTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_ITERATIVE_ADDITIVE_SCHWARZ_PRECONDITIONER=6 !<Additive Schwrz preconditioner type \see SOLVER_ROUTINES_IterativePreconditionerTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_NonlinearSolverTypes SOLVER_ROUTINES::NonlinearSolverTypes
  !> \brief The types of nonlinear solvers
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_NONLINEAR_NEWTON=1 !<Newton nonlinear solver type \see SOLVER_ROUTINES_NonlinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_NONLINEAR_BFGS_INVERSE=2 !<BFGS inverse nonlinear solver type \see SOLVER_ROUTINES_NonlinearSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_NONLINEAR_SQP=3 !<Sequential Quadratic Program nonlinear solver type \see SOLVER_ROUTINES_NonlinearSolverTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_NewtonSolverTypes SOLVER_ROUTINES::NewtonSolverTypes
  !> \brief The types of nonlinear Newton solvers
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_NEWTON_LINESEARCH=1 !<Newton line search nonlinear solver type \see SOLVER_ROUTINES_NewtonSolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_NEWTON_TRUSTREGION=2 !<Newton trust region nonlinear solver type \see SOLVER_ROUTINES_NewtonSolverTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_NewtonLineSearchTypes SOLVER_ROUTINES::NewtonLineSearchTypes
  !> \brief The types line search techniques for Newton line search nonlinear solvers
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_NEWTON_LINESEARCH_NONORMS=1 !<No norms line search for Newton line search nonlinear solves \see SOLVER_ROUTINES_NewtonLineSearchTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_NEWTON_LINESEARCH_NONE=2 !<No line search for Newton line search nonlinear solves \see SOLVER_ROUTINES_NewtonLineSearchTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_NEWTON_LINESEARCH_QUADRATIC=3 !<Quadratic search for Newton line search nonlinear solves \see SOLVER_ROUTINES_NewtonLineSearchTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_NEWTON_LINESEARCH_CUBIC=4!<Cubic search for Newton line search nonlinear solves \see SOLVER_ROUTINES_NewtonLineSearchTypes,SOLVER_ROUTINES
  !>@}
  
  !> \addtogroup SOLVER_ROUTINES_JacobianCalculationTypes SOLVER_ROUTINES::JacobianCalculationTypes
  !> \brief The Jacobian calculation types for a nonlinear solver 
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_NEWTON_JACOBIAN_NOT_CALCULATED=1 !<The Jacobian values will not be calculated for the nonlinear equations set \see SOLVER_ROUTINES_JacobianCalculationTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_NEWTON_JACOBIAN_ANALTYIC_CALCULATED=2 !<The Jacobian values will be calculated analytically for the nonlinear equations set \see SOLVER_ROUTINES_JacobianCalculationTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_NEWTON_JACOBIAN_FD_CALCULATED=3 !<The Jacobian values will be calcualted using finite differences for the nonlinear equations set \see SOLVER_ROUTINES_JacobianCalculationTypes,SOLVER_ROUTINES
  !>@}  

   !> \addtogroup SOLVER_ROUTINES_DynamicOrderTypes SOLVER_ROUTINES::DynamicOrderTypes
  !> \brief The order types for a dynamic solver 
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_FIRST_ORDER=1 !<Dynamic solver has first order terms \see SOLVER_ROUTINES_DynamicOrderTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_SECOND_ORDER=2 !<Dynamic solver has second order terms \see SOLVER_ROUTINES_DynamicOrderTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_DynamicLinearityTypes SOLVER_ROUTINES::DynamicLinearityTypes
  !> \brief The time linearity types for a dynamic solver 
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_LINEAR=1 !<Dynamic solver has linear terms \see SOLVER_ROUTINES_DynamicLinearityTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_NONLINEAR=2 !<Dynamic solver has nonlinear terms \see SOLVER_ROUTINES_DynamicLinearityTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_DynamicDegreeTypes SOLVER_ROUTINES::DynamicDegreeTypes
  !> \brief The time interpolation polynomial degree types for a dynamic solver 
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_FIRST_DEGREE=1 !<Dynamic solver uses a first degree polynomial for time interpolation \see SOLVER_ROUTINES_DynamicDegreeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_SECOND_DEGREE=2 !<Dynamic solver uses a second degree polynomial for time interpolation \see SOLVER_ROUTINES_DynamicDegreeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_THIRD_DEGREE=3 !<Dynamic solver uses a third degree polynomial for time interpolation \see SOLVER_ROUTINES_DynamicDegreeTypes,SOLVER_ROUTINES
  !>@}    
  
  !> \addtogroup SOLVER_ROUTINES_DynamicSchemeTypes SOLVER_ROUTINES::DynamicSchemeTypes
  !> \brief The types of dynamic solver scheme
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_EULER_SCHEME=1 !<Euler (explicit) dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_BACKWARD_EULER_SCHEME=2 !<Backward Euler (implicit) dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_CRANK_NICHOLSON_SCHEME=3 !<Crank-Nicholson dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_GALERKIN_SCHEME=4 !<Galerkin dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_ZLAMAL_SCHEME=5 !<Zlamal dynamic solver \see SOLVER_ROUTINES_DynamicorderTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_SECOND_DEGREE_GEAR_SCHEME=6 !<2nd degree Gear dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_SECOND_DEGREE_LINIGER1_SCHEME=7 !<1st 2nd degree Liniger dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_SECOND_DEGREE_LINIGER2_SCHEME=8 !<2nd 2nd degree Liniger dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_NEWMARK1_SCHEME=9 !<1st Newmark dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_NEWMARK2_SCHEME=10 !<2nd Newmark dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_NEWMARK3_SCHEME=11 !<3rd Newmark dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_THIRD_DEGREE_GEAR_SCHEME=12 !<3rd degree Gear dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_THIRD_DEGREE_LINIGER1_SCHEME=13 !<1st 3rd degree Liniger dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_THIRD_DEGREE_LINIGER2_SCHEME=14 !<2nd 3rd degree Liniger dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_HOUBOLT_SCHEME=15 !<Houbolt dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_WILSON_SCHEME=16 !<Wilson dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_BOSSAK_NEWMARK1_SCHEME=17 !<1st Bossak-Newmark dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_BOSSAK_NEWMARK2_SCHEME=18 !<2nd Bossak-Newmark dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_HILBERT_HUGHES_TAYLOR1_SCHEME=19 !<1st Hilbert-Hughes-Taylor dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_HILBERT_HUGHES_TAYLOR2_SCHEME=20 !<1st Hilbert-Hughes-Taylor dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DYNAMIC_USER_DEFINED_SCHEME=21 !<User specified degree and theta dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
  !>@}
  
  !> \addtogroup SOLVER_ROUTINES_DAETypes SOLVER_ROUTINES::DAETypes
  !> \brief The type of differential-algebraic equation
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_DIFFERENTIAL_ONLY=0 !<Differential equations only \see SOLVER_ROUTINES_DAETypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_INDEX_1=1 !<Index 1 differential-algebraic equation \see SOLVER_ROUTINES_DAETypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_INDEX_2=2 !<Index 2 differential-algebraic equation \see SOLVER_ROUTINES_DAETypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_INDEX_3=3 !<Index 3 differential-algebraic equation \see SOLVER_ROUTINES_DAETypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_DAESolverTypes SOLVER_ROUTINES::DAESolverTypes
  !> \brief The differential-algebraic equation solver types for a differential-algebraic equation solver 
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_EULER=1 !<Euler differential-algebraic equation solver \see SOLVER_ROUTINES_DAESolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_CRANK_NICHOLSON=2 !<Crank-Nicholson differential-algebraic equation solver \see SOLVER_ROUTINES_DAESolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_RUNGE_KUTTA=3 !<Runge-Kutta differential-algebraic equation solver \see SOLVER_ROUTINES_DAESolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_ADAMS_MOULTON=4 !<Adams-Moulton differential-algebraic equation solver \see SOLVER_ROUTINES_DAESolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_BDF=5 !<General BDF differential-algebraic equation solver \see SOLVER_ROUTINES_DAESolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_RUSH_LARSON=6 !<Rush-Larson differential-algebraic equation solver \see SOLVER_ROUTINES_DAESolverTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_EulerDAESolverTypes SOLVER_ROUTINES::EulerDAESolverTypes
  !> \brief The Euler solver types for a differential-algebriac equation solver 
  !> \see SOLVER_ROUTINES_DAESolverTypes,SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_EULER_FORWARD=1 !<Forward Euler differential equation solver \see SOLVER_ROUTINES_EulerDAESolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_EULER_BACKWARD=2 !<Backward Euler differential equation solver \see SOLVER_ROUTINES_EulerDAESolverTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_DAE_EULER_IMPROVED=3 !<Improved Euler differential equation solver \see SOLVER_ROUTINES_EulerDAESolverTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_SolutionInitialiseTypes SOLVER_ROUTINES::SolutionInitialiseTypes
  !> \brief The types of solution initialisation
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_SOLUTION_INITIALISE_ZERO=0 !<Initialise the solution by zeroing it before a solve \see SOLVER_ROUTINES_SolutionInitialiseTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_SOLUTION_INITIALISE_CURRENT_FIELD=1 !<Initialise the solution by copying in the current dependent field values \see SOLVER_ROUTINES_SolutionInitialiseTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_SOLUTION_INITIALISE_NO_CHANGE=2 !<Do not change the solution before a solve \see SOLVER_ROUTINES_SolutionInitialiseTypes,SOLVER_ROUTINES
  !>@}

  
  !> \addtogroup SOLVER_ROUTINES_OutputTypes SOLVER_ROUTINES::OutputTypes
  !> \brief The types of output
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_NO_OUTPUT=0 !<No output from the solver routines \see SOLVER_ROUTINES_OutputTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_PROGRESS_OUTPUT=1 !<Progress output from solver routines \see SOLVER_ROUTINES_OutputTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_TIMING_OUTPUT=2 !<Timing output from the solver routines plus below \see SOLVER_ROUTINES_OutputTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_SOLVER_OUTPUT=3 !<Solver specific output from the solver routines plus below \see SOLVER_ROUTINES_OutputTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_MATRIX_OUTPUT=4 !<SolVER matrices output from the solver routines plus below\see SOLVER_ROUTINES_OutputTypes,SOLVER_ROUTINES
  !>@}

  !> \addtogroup SOLVER_ROUTINES_SparsityTypes SOLVER_ROUTINES::SparsityTypes
  !> \brief The types of sparse solver matrices
  !> \see SOLVER_ROUTINES
  !>@{
  INTEGER(INTG), PARAMETER :: SOLVER_SPARSE_MATRICES=1 !<Use sparse solver matrices \see SOLVER_ROUTINES_SparsityTypes,SOLVER_ROUTINES
  INTEGER(INTG), PARAMETER :: SOLVER_FULL_MATRICES=2 !<Use fully populated solver matrices \see SOLVER_ROUTINES_SparsityTypes,SOLVER_ROUTINES
  !>@}
  !Module types

  !Module variables

  !Interfaces

  INTERFACE SOLVER_DYNAMIC_THETA_SET
    MODULE PROCEDURE SOLVER_DYNAMIC_THETA_SET_DP1
    MODULE PROCEDURE SOLVER_DYNAMIC_THETA_SET_DP
  END INTERFACE !SOLVER_DYNAMIC_THETA_SET  

  PUBLIC SOLVER_LINEAR_TYPE,SOLVER_NONLINEAR_TYPE,SOLVER_DYNAMIC_TYPE,SOLVER_DAE_TYPE,SOLVER_EIGENPROBLEM_TYPE,SOLVER_OPTIMISER_TYPE

  PUBLIC SOLVER_CMISS_LIBRARY,SOLVER_PETSC_LIBRARY,SOLVER_MUMPS_LIBRARY,SOLVER_SUPERLU_LIBRARY,SOLVER_SPOOLES_LIBRARY, &
    & SOLVER_UMFPACK_LIBRARY,SOLVER_LUSOL_LIBRARY,SOLVER_ESSL_LIBRARY,SOLVER_LAPACK_LIBRARY,SOLVER_TAO_LIBRARY, &
    & SOLVER_HYPRE_LIBRARY

  PUBLIC SOLVER_LINEAR_DIRECT_SOLVE_TYPE,SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE
 
  PUBLIC SOLVER_DIRECT_LU,SOLVER_DIRECT_CHOLESKY,SOLVER_DIRECT_SVD

  PUBLIC SOLVER_ITERATIVE_RICHARDSON,SOLVER_ITERATIVE_CHEBYCHEV,SOLVER_ITERATIVE_CONJUGATE_GRADIENT, &
    & SOLVER_ITERATIVE_BICONJUGATE_GRADIENT,SOLVER_ITERATIVE_GMRES,SOLVER_ITERATIVE_BiCGSTAB,SOLVER_ITERATIVE_CONJGRAD_SQUARED

  PUBLIC SOLVER_ITERATIVE_NO_PRECONDITIONER,SOLVER_ITERATIVE_JACOBI_PRECONDITIONER,SOLVER_ITERATIVE_BLOCK_JACOBI_PRECONDITIONER, &
    & SOLVER_ITERATIVE_SOR_PRECONDITIONER,SOLVER_ITERATIVE_INCOMPLETE_CHOLESKY_PRECONDITIONER, &
    & SOLVER_ITERATIVE_INCOMPLETE_LU_PRECONDITIONER,SOLVER_ITERATIVE_ADDITIVE_SCHWARZ_PRECONDITIONER

  PUBLIC SOLVER_NONLINEAR_NEWTON,SOLVER_NONLINEAR_BFGS_INVERSE,SOLVER_NONLINEAR_SQP

  PUBLIC SOLVER_NEWTON_LINESEARCH,SOLVER_NEWTON_TRUSTREGION

  PUBLIC SOLVER_NEWTON_LINESEARCH_NONORMS,SOLVER_NEWTON_LINESEARCH_NONE,SOLVER_NEWTON_LINESEARCH_QUADRATIC, &
    & SOLVER_NEWTON_LINESEARCH_CUBIC

  PUBLIC SOLVER_NEWTON_JACOBIAN_NOT_CALCULATED,SOLVER_NEWTON_JACOBIAN_ANALTYIC_CALCULATED, &
    & SOLVER_NEWTON_JACOBIAN_FD_CALCULATED
  
  PUBLIC SOLVER_DYNAMIC_LINEAR,SOLVER_DYNAMIC_NONLINEAR,SOLVER_DYNAMIC_LINEARITY_TYPE_SET

  PUBLIC SOLVER_DYNAMIC_FIRST_ORDER,SOLVER_DYNAMIC_SECOND_ORDER

  PUBLIC SOLVER_DYNAMIC_FIRST_DEGREE,SOLVER_DYNAMIC_SECOND_DEGREE,SOLVER_DYNAMIC_THIRD_DEGREE

  PUBLIC SOLVER_DYNAMIC_EULER_SCHEME,SOLVER_DYNAMIC_BACKWARD_EULER_SCHEME,SOLVER_DYNAMIC_CRANK_NICHOLSON_SCHEME, &
    & SOLVER_DYNAMIC_GALERKIN_SCHEME,SOLVER_DYNAMIC_ZLAMAL_SCHEME,SOLVER_DYNAMIC_SECOND_DEGREE_GEAR_SCHEME, &
    & SOLVER_DYNAMIC_SECOND_DEGREE_LINIGER1_SCHEME,SOLVER_DYNAMIC_SECOND_DEGREE_LINIGER2_SCHEME, &
    & SOLVER_DYNAMIC_NEWMARK1_SCHEME,SOLVER_DYNAMIC_NEWMARK2_SCHEME,SOLVER_DYNAMIC_NEWMARK3_SCHEME, &
    & SOLVER_DYNAMIC_THIRD_DEGREE_GEAR_SCHEME,SOLVER_DYNAMIC_THIRD_DEGREE_LINIGER1_SCHEME, &
    & SOLVER_DYNAMIC_THIRD_DEGREE_LINIGER2_SCHEME,SOLVER_DYNAMIC_HOUBOLT_SCHEME,SOLVER_DYNAMIC_WILSON_SCHEME, &
    & SOLVER_DYNAMIC_BOSSAK_NEWMARK1_SCHEME,SOLVER_DYNAMIC_BOSSAK_NEWMARK2_SCHEME, &
    & SOLVER_DYNAMIC_HILBERT_HUGHES_TAYLOR1_SCHEME,SOLVER_DYNAMIC_HILBERT_HUGHES_TAYLOR2_SCHEME, &
    & SOLVER_DYNAMIC_USER_DEFINED_SCHEME

  PUBLIC SOLVER_DAE_DIFFERENTIAL_ONLY,SOLVER_DAE_INDEX_1,SOLVER_DAE_INDEX_2,SOLVER_DAE_INDEX_3

  PUBLIC SOLVER_DAE_EULER,SOLVER_DAE_CRANK_NICHOLSON,SOLVER_DAE_RUNGE_KUTTA,SOLVER_DAE_ADAMS_MOULTON,SOLVER_DAE_BDF, &
    & SOLVER_DAE_RUSH_LARSON

  PUBLIC SOLVER_DAE_EULER_FORWARD,SOLVER_DAE_EULER_BACKWARD,SOLVER_DAE_EULER_IMPROVED

  PUBLIC SOLVER_SOLUTION_INITIALISE_ZERO,SOLVER_SOLUTION_INITIALISE_CURRENT_FIELD,SOLVER_SOLUTION_INITIALISE_NO_CHANGE
  
  PUBLIC SOLVER_NO_OUTPUT,SOLVER_PROGRESS_OUTPUT,SOLVER_TIMING_OUTPUT,SOLVER_SOLVER_OUTPUT,SOLVER_MATRIX_OUTPUT
  
  PUBLIC SOLVER_SPARSE_MATRICES,SOLVER_FULL_MATRICES

  PUBLIC SOLVER_EQUATIONS_LINEAR,SOLVER_EQUATIONS_NONLINEAR

  PUBLIC SOLVER_EQUATIONS_STATIC,SOLVER_EQUATIONS_QUASISTATIC,SOLVER_EQUATIONS_FIRST_ORDER_DYNAMIC, &
    & SOLVER_EQUATIONS_SECOND_ORDER_DYNAMIC

  PUBLIC SOLVER_DAE_SOLVER_TYPE_GET,SOLVER_DAE_SOLVER_TYPE_SET

  PUBLIC SOLVER_DAE_TIMES_SET
  
  PUBLIC SOLVER_DAE_EULER_SOLVER_TYPE_GET,SOLVER_DAE_EULER_SOLVER_TYPE_SET
  
  PUBLIC SOLVER_DESTROY
  
  PUBLIC SOLVER_DYNAMIC_DEGREE_GET,SOLVER_DYNAMIC_DEGREE_SET

  PUBLIC SOLVER_DYNAMIC_LINEAR_SOLVER_GET,SOLVER_DYNAMIC_NONLINEAR_SOLVER_GET

  PUBLIC SOLVER_DYNAMIC_LINEARITY_TYPE_GET
  
  PUBLIC SOLVER_DYNAMIC_ORDER_SET

  PUBLIC SOLVER_DYNAMIC_SCHEME_SET

  PUBLIC SOLVER_DYNAMIC_THETA_SET 

  PUBLIC SOLVER_DYNAMIC_ALE_SET

  PUBLIC SOLVER_DYNAMIC_UPDATE_BC_SET

  PUBLIC SOLVER_DYNAMIC_TIMES_SET

  PUBLIC SOLVER_EQUATIONS_CREATE_FINISH,SOLVER_EQUATIONS_CREATE_START

  PUBLIC SOLVER_EQUATIONS_DESTROY
  
  PUBLIC SOLVER_EQUATIONS_EQUATIONS_SET_ADD

  PUBLIC SOLVER_EQUATIONS_INTERFACE_CONDITION_ADD

 PUBLIC SOLVER_EQUATIONS_LINEARITY_TYPE_SET

  PUBLIC SOLVER_EQUATIONS_SPARSITY_TYPE_SET
  
  PUBLIC SOLVER_EQUATIONS_TIME_DEPENDENCE_TYPE_SET
  
  PUBLIC SOLVER_LIBRARY_TYPE_GET,SOLVER_LIBRARY_TYPE_SET

  PUBLIC SOLVER_LINEAR_TYPE_SET
  
  PUBLIC SOLVER_LINEAR_DIRECT_TYPE_SET

  PUBLIC SOLVER_LINEAR_ITERATIVE_ABSOLUTE_TOLERANCE_SET

  PUBLIC SOLVER_LINEAR_ITERATIVE_DIVERGENCE_TOLERANCE_SET
  
  PUBLIC SOLVER_LINEAR_ITERATIVE_GMRES_RESTART_SET

  PUBLIC SOLVER_LINEAR_ITERATIVE_MAXIMUM_ITERATIONS_SET

  PUBLIC SOLVER_LINEAR_ITERATIVE_PRECONDITIONER_TYPE_SET

  PUBLIC SOLVER_LINEAR_ITERATIVE_RELATIVE_TOLERANCE_SET
  
  PUBLIC SOLVER_LINEAR_ITERATIVE_SOLUTION_INIT_TYPE_SET

  PUBLIC SOLVER_LINEAR_ITERATIVE_TYPE_SET

  PUBLIC SOLVER_MATRICES_DYNAMIC_ASSEMBLE,SOLVER_MATRICES_STATIC_ASSEMBLE

  PUBLIC SOLVER_NEWTON_ABSOLUTE_TOLERANCE_SET

  PUBLIC SOLVER_NEWTON_LINESEARCH_ALPHA_SET

  PUBLIC SOLVER_NEWTON_LINESEARCH_TYPE_SET

  PUBLIC SOLVER_NEWTON_JACOBIAN_CALCULATION_TYPE_SET
  
  PUBLIC SOLVER_NEWTON_LINEAR_SOLVER_GET

  PUBLIC SOLVER_NEWTON_LINESEARCH_MAXSTEP_SET

  PUBLIC SOLVER_NEWTON_LINESEARCH_STEPTOL_SET

  PUBLIC SOLVER_NEWTON_MAXIMUM_ITERATIONS_SET

  PUBLIC SOLVER_NEWTON_MAXIMUM_FUNCTION_EVALUATIONS_SET

  PUBLIC SOLVER_NEWTON_SOLUTION_INIT_TYPE_SET

  PUBLIC SOLVER_NEWTON_SOLUTION_TOLERANCE_SET
  
  PUBLIC SOLVER_NEWTON_RELATIVE_TOLERANCE_SET

  PUBLIC SOLVER_NEWTON_TRUSTREGION_DELTA0_SET

  PUBLIC SOLVER_NEWTON_TRUSTREGION_TOLERANCE_SET

  PUBLIC SOLVER_NEWTON_TYPE_SET

  PUBLIC SOLVER_NONLINEAR_MONITOR

  PUBLIC SOLVER_NONLINEAR_TYPE_SET
  
  PUBLIC SOLVER_OUTPUT_TYPE_SET
  
  PUBLIC SOLVER_SOLVE
  
  PUBLIC SOLVER_SOLVER_EQUATIONS_GET

  PUBLIC SOLVER_TIME_STEPPING_MONITOR
  
  PUBLIC SOLVER_TYPE_SET

  PUBLIC SOLVER_VARIABLES_DYNAMIC_FIELD_UPDATE

  PUBLIC SOLVER_VARIABLES_DYNAMIC_NONLINEAR_UPDATE

  PUBLIC SOLVER_VARIABLES_FIELD_UPDATE

  PUBLIC SOLVERS_CREATE_FINISH,SOLVERS_CREATE_START

  PUBLIC SOLVERS_DESTROY

  PUBLIC SOLVERS_NUMBER_SET

  PUBLIC SOLVERS_SOLVER_GET
  
CONTAINS

  !
  !================================================================================================================================
  !

  !>Finishes the process of creating a solver 
  SUBROUTINE SOLVER_CREATE_FINISH(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        !Set the finished flag. The final solver finish will be done once the solver equations have been finished.
        IF(ASSOCIATED(SOLVER%LINKED_SOLVER)) THEN
          SOLVER%LINKED_SOLVER%SOLVER_FINISHED=.TRUE.
        ENDIF
        SOLVER%SOLVER_FINISHED=.TRUE.
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_CREATE_FINISH")
    RETURN 1
   
  END SUBROUTINE SOLVER_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Finalise an Adams-Moulton differential-algebraic equation solver and deallocate all memory.
  SUBROUTINE SOLVER_DAE_ADAMS_MOULTON_FINALISE(ADAMS_MOULTON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(ADAMS_MOULTON_DAE_SOLVER_TYPE), POINTER :: ADAMS_MOULTON_SOLVER !<A pointer the Adams-Moulton differential-algebraic equation solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("SOLVER_DAE_ADAMS_MOULTON_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(ADAMS_MOULTON_SOLVER)) THEN
      DEALLOCATE(ADAMS_MOULTON_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_ADAMS_MOULTON_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_ADAMS_MOULTON_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_ADAMS_MOULTON_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_ADAMS_MOULTON_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise an Adams-Moulton solver for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_ADAMS_MOULTON_INITIALISE(DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer the differential-algebraic equation solver to initialise an Adams-Moulton solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_DAE_ADAMS_MOULTON_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      IF(ASSOCIATED(DAE_SOLVER%ADAMS_MOULTON_SOLVER)) THEN
        CALL FLAG_ERROR("Adams-Moulton solver is already associated for this differential-algebraic equation solver.", &
          & ERR,ERROR,*998)
      ELSE
        !Allocate the Adams-Moulton solver
        ALLOCATE(DAE_SOLVER%ADAMS_MOULTON_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate Adams-Moulton solver.",ERR,ERROR,*999)
        !Initialise
        DAE_SOLVER%ADAMS_MOULTON_SOLVER%DAE_SOLVER=>DAE_SOLVER
        DAE_SOLVER%ADAMS_MOULTON_SOLVER%SOLVER_LIBRARY=0
        !Defaults
      ENDIF      
    ELSE
      CALL FLAG_ERROR("Differential-algebraic equation solver is not associated.",ERR,ERROR,*998)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_ADAMS_MOULTON_INITIALISE")
    RETURN
999 CALL SOLVER_DAE_ADAMS_MOULTON_FINALISE(DAE_SOLVER%ADAMS_MOULTON_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_DAE_ADAMS_MOULTON_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_ADAMS_MOULTON_INITIALISE")
    RETURN 1
    
  END SUBROUTINE SOLVER_DAE_ADAMS_MOULTON_INITIALISE

  !
  !================================================================================================================================
  !

  !>Solve using an Adams-Moulton differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_ADAMS_MOULTON_SOLVE(ADAMS_MOULTON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(ADAMS_MOULTON_DAE_SOLVER_TYPE), POINTER :: ADAMS_MOULTON_SOLVER !<A pointer the Adams-Moulton differential-algebraic equation solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DAE_ADAMS_MOULTON_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(ADAMS_MOULTON_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Adams-Moulton differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_ADAMS_MOULTON_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_ADAMS_MOULTON_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_ADAMS_MOULTON_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_ADAMS_MOULTON_SOLVE

  !
  !================================================================================================================================
  !

  !>Finishes the process of creating a differential-algebraic equation solver 
  SUBROUTINE SOLVER_DAE_CREATE_FINISH(DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer to the differential-algebraic equation solver to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DAE_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_DAE_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_DAE_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_CREATE_FINISH")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Finalise a backward Euler differential-algebraic equation and deallocate all memory.
  SUBROUTINE SOLVER_DAE_EULER_BACKWARD_FINALISE(BACKWARD_EULER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(BACKWARD_EULER_DAE_SOLVER_TYPE), POINTER :: BACKWARD_EULER_SOLVER !<A pointer the backward Euler differential-algebraic equation solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("SOLVER_DAE_EULER_BACKWARD_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(BACKWARD_EULER_SOLVER)) THEN
      DEALLOCATE(BACKWARD_EULER_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_BACKWARD_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_BACKWARD_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_BACKWARD_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_BACKWARD_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a backward Euler solver for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_EULER_BACKWARD_INITIALISE(EULER_DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_DAE_SOLVER !<A pointer the Euler differential-algebraic equation solver to initialise a backward Euler solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_DAE_EULER_BACKWARD_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(EULER_DAE_SOLVER)) THEN
      IF(ASSOCIATED(EULER_DAE_SOLVER%BACKWARD_EULER_SOLVER)) THEN
        CALL FLAG_ERROR("Backward Euler solver is already associated for this Euler differential-algebraic equation solver.", &
          & ERR,ERROR,*998)
      ELSE
        !Allocate the backward Euler solver
        ALLOCATE(EULER_DAE_SOLVER%BACKWARD_EULER_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate backward Euler solver.",ERR,ERROR,*999)
        !Initialise
        EULER_DAE_SOLVER%BACKWARD_EULER_SOLVER%EULER_DAE_SOLVER=>EULER_DAE_SOLVER
        EULER_DAE_SOLVER%BACKWARD_EULER_SOLVER%SOLVER_LIBRARY=0
        !Defaults
      ENDIF      
    ELSE
      CALL FLAG_ERROR("Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*998)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_BACKWARD_INITIALISE")
    RETURN
999 CALL SOLVER_DAE_EULER_BACKWARD_FINALISE(EULER_DAE_SOLVER%BACKWARD_EULER_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_DAE_EULER_BACKWARD_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_BACKWARD_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_BACKWARD_INITIALISE

  !
  !================================================================================================================================
  !

  !>Solve using a backward Euler differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_EULER_BACKWARD_SOLVE(BACKWARD_EULER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(BACKWARD_EULER_DAE_SOLVER_TYPE), POINTER :: BACKWARD_EULER_SOLVER !<A pointer the backward Euler differential-algebraic equation solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DAE_EULER_BACKWARD_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(BACKWARD_EULER_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Backward Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_BACKWARD_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_BACKWARD_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_BACKWARD_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_BACKWARD_SOLVE

  !
  !================================================================================================================================
  !

  !>Finalise an Euler differential-algebraic equation solver and deallocate all memory.
  SUBROUTINE SOLVER_DAE_EULER_FINALISE(EULER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_SOLVER !<A pointer the Euler differential-algebraic equation solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("SOLVER_DAE_EULER_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(EULER_SOLVER)) THEN
      CALL SOLVER_DAE_EULER_FORWARD_FINALISE(EULER_SOLVER%FORWARD_EULER_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_DAE_EULER_BACKWARD_FINALISE(EULER_SOLVER%BACKWARD_EULER_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_DAE_EULER_IMPROVED_FINALISE(EULER_SOLVER%IMPROVED_EULER_SOLVER,ERR,ERROR,*999)      
      DEALLOCATE(EULER_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_FINALISE

  !
  !================================================================================================================================
  !

  !>Finalise a forward Euler differential-algebraic equation and deallocate all memory.
  SUBROUTINE SOLVER_DAE_EULER_FORWARD_FINALISE(FORWARD_EULER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(FORWARD_EULER_DAE_SOLVER_TYPE), POINTER :: FORWARD_EULER_SOLVER !<A pointer the forward Euler differential-algebraic equation solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("SOLVER_DAE_EULER_FORWARD_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(FORWARD_EULER_SOLVER)) THEN
      DEALLOCATE(FORWARD_EULER_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_FORWARD_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_FORWARD_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_FORWARD_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_FORWARD_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a forward Euler solver for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_EULER_FORWARD_INITIALISE(EULER_DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_DAE_SOLVER !<A pointer the Euler differential-algebraic equation solver to initialise a forward Euler solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_DAE_EULER_FORWARD_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(EULER_DAE_SOLVER)) THEN
      IF(ASSOCIATED(EULER_DAE_SOLVER%FORWARD_EULER_SOLVER)) THEN
        CALL FLAG_ERROR("Forward Euler solver is already associated for this Euler differential-algebraic equation solver.", &
          & ERR,ERROR,*998)
      ELSE
        !Allocate the forward Euler solver
        ALLOCATE(EULER_DAE_SOLVER%FORWARD_EULER_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate forward Euler solver.",ERR,ERROR,*999)
        !Initialise
        EULER_DAE_SOLVER%FORWARD_EULER_SOLVER%EULER_DAE_SOLVER=>EULER_DAE_SOLVER
        EULER_DAE_SOLVER%FORWARD_EULER_SOLVER%SOLVER_LIBRARY=SOLVER_CMISS_LIBRARY
        !Defaults
      ENDIF      
    ELSE
      CALL FLAG_ERROR("Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*998)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_FORWARD_INITIALISE")
    RETURN
999 CALL SOLVER_DAE_EULER_FORWARD_FINALISE(EULER_DAE_SOLVER%FORWARD_EULER_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_DAE_EULER_FORWARD_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_FORWARD_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_FORWARD_INITIALISE

  !
  !================================================================================================================================
  !

  !>Solve using a forward Euler differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_EULER_FORWARD_SOLVE(FORWARD_EULER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(FORWARD_EULER_DAE_SOLVER_TYPE), POINTER :: FORWARD_EULER_SOLVER !<A pointer the forward Euler differential-algebraic equation solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_SOLVER
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    
    CALL ENTERS("SOLVER_DAE_EULER_FORWARD_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(FORWARD_EULER_SOLVER)) THEN
      EULER_SOLVER=>FORWARD_EULER_SOLVER%EULER_DAE_SOLVER
      IF(ASSOCIATED(EULER_SOLVER)) THEN
        DAE_SOLVER=>EULER_SOLVER%DAE_SOLVER
        IF(ASSOCIATED(DAE_SOLVER)) THEN
          SOLVER=>DAE_SOLVER%SOLVER
          IF(ASSOCIATED(SOLVER)) THEN
            SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
            IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
              SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
              IF(ASSOCIATED(SOLVER_MAPPING)) THEN
              ELSE
                CALL FLAG_ERROR("Solver equations solver mapping is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
          ENDIF
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Forward Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_FORWARD_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_FORWARD_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_FORWARD_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_FORWARD_SOLVE

  !
  !================================================================================================================================
  !

  !>Finalise an improved Euler differential-algebaic equation and deallocate all memory.
  SUBROUTINE SOLVER_DAE_EULER_IMPROVED_FINALISE(IMPROVED_EULER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(IMPROVED_EULER_DAE_SOLVER_TYPE), POINTER :: IMPROVED_EULER_SOLVER !<A pointer the improved Euler differential-algebraic equation solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("SOLVER_DAE_EULER_IMPROVED_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(IMPROVED_EULER_SOLVER)) THEN
      DEALLOCATE(IMPROVED_EULER_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_IMPROVED_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_IMPROVED_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_IMPROVED_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_IMPROVED_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise an improved Euler solver for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_EULER_IMPROVED_INITIALISE(EULER_DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_DAE_SOLVER !<A pointer the Euler differential-algebraic equation solver to initialise an improved Euler solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_DAE_EULER_IMPROVED_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(EULER_DAE_SOLVER)) THEN
      IF(ASSOCIATED(EULER_DAE_SOLVER%IMPROVED_EULER_SOLVER)) THEN
        CALL FLAG_ERROR("Improved Euler solver is already associated for this Euler differential-algebraic equation solver.", &
          & ERR,ERROR,*998)
      ELSE
        !Allocate the improved Euler solver
        ALLOCATE(EULER_DAE_SOLVER%IMPROVED_EULER_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate improved Euler solver.",ERR,ERROR,*999)
        !Initialise
        EULER_DAE_SOLVER%IMPROVED_EULER_SOLVER%EULER_DAE_SOLVER=>EULER_DAE_SOLVER
        EULER_DAE_SOLVER%IMPROVED_EULER_SOLVER%SOLVER_LIBRARY=0
        !Defaults
      ENDIF      
    ELSE
      CALL FLAG_ERROR("Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*998)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_IMPROVED_INITIALISE")
    RETURN
999 CALL SOLVER_DAE_EULER_IMPROVED_FINALISE(EULER_DAE_SOLVER%IMPROVED_EULER_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_DAE_EULER_IMPROVED_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_IMPROVED_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_IMPROVED_INITIALISE

  !
  !================================================================================================================================
  !

  !>Solve using an improved Euler differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_EULER_IMPROVED_SOLVE(IMPROVED_EULER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(IMPROVED_EULER_DAE_SOLVER_TYPE), POINTER :: IMPROVED_EULER_SOLVER !<A pointer the improved Euler differential-algebraic equation solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DAE_EULER_IMPROVED_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(IMPROVED_EULER_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Improved Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_IMPROVED_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_IMPROVED_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_IMPROVED_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_IMPROVED_SOLVE

  !
  !================================================================================================================================
  !

  !>Initialise an Euler solver for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_EULER_INITIALISE(DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer the differential-algebraic equation solver to initialise an Euler solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_DAE_EULER_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      IF(ASSOCIATED(DAE_SOLVER%EULER_SOLVER)) THEN
        CALL FLAG_ERROR("Euler solver is already associated for this differential-algebraic equation solver.",ERR,ERROR,*998)
      ELSE
        !Allocate the Euler solver
        ALLOCATE(DAE_SOLVER%EULER_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate Euler solver.",ERR,ERROR,*999)
        !Initialise
        DAE_SOLVER%EULER_SOLVER%DAE_SOLVER=>DAE_SOLVER
        NULLIFY(DAE_SOLVER%EULER_SOLVER%FORWARD_EULER_SOLVER)
        NULLIFY(DAE_SOLVER%EULER_SOLVER%BACKWARD_EULER_SOLVER)
        NULLIFY(DAE_SOLVER%EULER_SOLVER%IMPROVED_EULER_SOLVER)
        !Default to a forward Euler solver
        CALL SOLVER_DAE_EULER_FORWARD_INITIALISE(DAE_SOLVER%EULER_SOLVER,ERR,ERROR,*999)
        DAE_SOLVER%EULER_SOLVER%EULER_TYPE=SOLVER_DAE_EULER_FORWARD
      ENDIF
    ELSE
      CALL FLAG_ERROR("Differential-algebraic equation solver is not associated.",ERR,ERROR,*998)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_INITIALISE")
    RETURN
999 CALL SOLVER_DAE_EULER_FINALISE(DAE_SOLVER%EULER_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_DAE_EULER_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for an Euler differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_EULER_LIBRARY_TYPE_GET(EULER_DAE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_DAE_SOLVER !<A pointer the differential-algebraic equation Euler solver to get the library type for
    INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On return, the type of library used for the differential-algebraic equation Euler solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(BACKWARD_EULER_DAE_SOLVER_TYPE), POINTER :: BACKWARD_EULER_DAE_SOLVER
    TYPE(FORWARD_EULER_DAE_SOLVER_TYPE), POINTER :: FORWARD_EULER_DAE_SOLVER
    TYPE(IMPROVED_EULER_DAE_SOLVER_TYPE), POINTER :: IMPROVED_EULER_DAE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_DAE_EULER_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(EULER_DAE_SOLVER)) THEN
      SELECT CASE(EULER_DAE_SOLVER%EULER_TYPE)
      CASE(SOLVER_DAE_EULER_FORWARD)
        FORWARD_EULER_DAE_SOLVER=>EULER_DAE_SOLVER%FORWARD_EULER_SOLVER
        IF(ASSOCIATED(FORWARD_EULER_DAE_SOLVER)) THEN
          SOLVER_LIBRARY_TYPE=FORWARD_EULER_DAE_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("The forward Euler differntial-algebraic equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_EULER_BACKWARD)
        BACKWARD_EULER_DAE_SOLVER=>EULER_DAE_SOLVER%BACKWARD_EULER_SOLVER
        IF(ASSOCIATED(BACKWARD_EULER_DAE_SOLVER)) THEN
          SOLVER_LIBRARY_TYPE=BACKWARD_EULER_DAE_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("The backward Euler differntial-algebraic equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_EULER_IMPROVED)
        IMPROVED_EULER_DAE_SOLVER=>EULER_DAE_SOLVER%IMPROVED_EULER_SOLVER
        IF(ASSOCIATED(IMPROVED_EULER_DAE_SOLVER)) THEN
          SOLVER_LIBRARY_TYPE=IMPROVED_EULER_DAE_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("The improved Euler differntial-algebraic equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The Euler differential-algebraic equations solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(EULER_DAE_SOLVER%EULER_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Euler DAE solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DAE_EULER_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library to use for an Euler differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_EULER_LIBRARY_TYPE_SET(EULER_DAE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_DAE_SOLVER !<A pointer the Euler differential-algebraic equation solver to set the library type for
    INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library for the Euler differential-algebraic equation solver to set \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(BACKWARD_EULER_DAE_SOLVER_TYPE), POINTER :: BACKWARD_EULER_DAE_SOLVER
    TYPE(FORWARD_EULER_DAE_SOLVER_TYPE), POINTER :: FORWARD_EULER_DAE_SOLVER
    TYPE(IMPROVED_EULER_DAE_SOLVER_TYPE), POINTER :: IMPROVED_EULER_DAE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_DAE_EULER_LIBRARY_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(EULER_DAE_SOLVER)) THEN
      SELECT CASE(EULER_DAE_SOLVER%EULER_TYPE)
      CASE(SOLVER_DAE_EULER_FORWARD)
        FORWARD_EULER_DAE_SOLVER=>EULER_DAE_SOLVER%FORWARD_EULER_SOLVER
        IF(ASSOCIATED(FORWARD_EULER_DAE_SOLVER)) THEN
          SELECT CASE(SOLVER_LIBRARY_TYPE)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a forward Euler DAE solver."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("The forward Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_EULER_BACKWARD)
        BACKWARD_EULER_DAE_SOLVER=>EULER_DAE_SOLVER%BACKWARD_EULER_SOLVER
        IF(ASSOCIATED(BACKWARD_EULER_DAE_SOLVER)) THEN
          SELECT CASE(SOLVER_LIBRARY_TYPE)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a backward Euler DAE solver."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("The backward Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_EULER_IMPROVED)
        IMPROVED_EULER_DAE_SOLVER=>EULER_DAE_SOLVER%IMPROVED_EULER_SOLVER
        IF(ASSOCIATED(IMPROVED_EULER_DAE_SOLVER)) THEN
          SELECT CASE(SOLVER_LIBRARY_TYPE)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
              & " is invalid for an improved Euler DAE solver."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("The improved Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The Euler differential-algebraic equations solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(EULER_DAE_SOLVER%EULER_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("The Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DAE_EULER_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_LIBRARY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_LIBRARY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Solve using an Euler differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_EULER_SOLVE(EULER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_SOLVER !<A pointer the Euler differential-algebraic equation solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_DAE_EULER_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(EULER_SOLVER)) THEN
      SELECT CASE(EULER_SOLVER%EULER_TYPE)
      CASE(SOLVER_DAE_EULER_FORWARD)
        CALL SOLVER_DAE_EULER_FORWARD_SOLVE(EULER_SOLVER%FORWARD_EULER_SOLVER,ERR,ERROR,*999)
      CASE(SOLVER_DAE_EULER_BACKWARD)
        CALL SOLVER_DAE_EULER_BACKWARD_SOLVE(EULER_SOLVER%BACKWARD_EULER_SOLVER,ERR,ERROR,*999)
      CASE(SOLVER_DAE_EULER_IMPROVED)
        CALL SOLVER_DAE_EULER_IMPROVED_SOLVE(EULER_SOLVER%IMPROVED_EULER_SOLVER,ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The Euler differential-algebraic equation solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(EULER_SOLVER%EULER_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_SOLVE

  !
  !================================================================================================================================
  !
  
  !>Returns the solve type for an Euler differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_EULER_SOLVER_TYPE_GET(SOLVER,DAE_EULER_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the Euler differential equation solver to get type for 
    INTEGER(INTG), INTENT(OUT) :: DAE_EULER_TYPE !<On return, the type of Euler solver for the Euler differential-algebraic equation to set \see SOLVER_ROUTINES_EulerDAESolverTypes,SOLVER_ROUTINES.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_DAE_SOLVER
     
    CALL ENTERS("SOLVER_DAE_EULER_SOLVER_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        IF(SOLVER%SOLVE_TYPE==SOLVER_DAE_TYPE) THEN
          DAE_SOLVER=>SOLVER%DAE_SOLVER
          IF(ASSOCIATED(DAE_SOLVER)) THEN
            IF(DAE_SOLVER%DAE_SOLVE_TYPE==SOLVER_DAE_EULER) THEN
              EULER_DAE_SOLVER=>DAE_SOLVER%EULER_SOLVER
              IF(ASSOCIATED(EULER_DAE_SOLVER)) THEN
                DAE_EULER_TYPE=EULER_DAE_SOLVER%EULER_TYPE
              ELSE
                CALL FLAG_ERROR("The differential-algebraic equation solver Euler solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver differential-algebraic equation solver is not an Euler differential-algebraic "// &
                & "equation solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a differential-algebraic equation solver.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_SOLVER_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_SOLVER_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_SOLVER_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_SOLVER_TYPE_GET

  !
  !================================================================================================================================
  !
  
  !>Sets/changes the solve type for an Euler differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_EULER_SOLVER_TYPE_SET(SOLVER,DAE_EULER_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the Euler differential equation solver to set type for 
    INTEGER(INTG), INTENT(IN) :: DAE_EULER_TYPE !<The type of Euler solver for the Euler differential-algebraic equation to set \see SOLVER_ROUTINES_EulerDAESolverTypes,SOLVER_ROUTINES.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_DAE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
     
    CALL ENTERS("SOLVER_DAE_EULER_SOLVER_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_DAE_TYPE) THEN
          DAE_SOLVER=>SOLVER%DAE_SOLVER
          IF(ASSOCIATED(DAE_SOLVER)) THEN
            IF(DAE_SOLVER%DAE_SOLVE_TYPE==SOLVER_DAE_EULER) THEN
              EULER_DAE_SOLVER=>DAE_SOLVER%EULER_SOLVER
              IF(ASSOCIATED(EULER_DAE_SOLVER)) THEN
                IF(DAE_EULER_TYPE/=EULER_DAE_SOLVER%EULER_TYPE) THEN
                  !Intialise the new Euler differential-algebraic equation solver type
                  SELECT CASE(DAE_EULER_TYPE)
                  CASE(SOLVER_DAE_EULER_FORWARD)
                    CALL SOLVER_DAE_EULER_FORWARD_INITIALISE(EULER_DAE_SOLVER,ERR,ERROR,*999)
                  CASE(SOLVER_DAE_EULER_BACKWARD)
                    CALL SOLVER_DAE_EULER_BACKWARD_INITIALISE(EULER_DAE_SOLVER,ERR,ERROR,*999)
                  CASE(SOLVER_DAE_EULER_IMPROVED)
                    CALL SOLVER_DAE_EULER_IMPROVED_INITIALISE(EULER_DAE_SOLVER,ERR,ERROR,*999)
                  CASE DEFAULT
                    LOCAL_ERROR="The specified Euler differential-algebraic equation solver type of "// &
                      & TRIM(NUMBER_TO_VSTRING(DAE_EULER_TYPE,"*",ERR,ERROR))//" is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT
                  !Finalise the old Euler differential-algebraic equation solver type
                  SELECT CASE(EULER_DAE_SOLVER%EULER_TYPE)
                  CASE(SOLVER_DAE_EULER_FORWARD)
                    CALL SOLVER_DAE_EULER_FORWARD_FINALISE(EULER_DAE_SOLVER%FORWARD_EULER_SOLVER,ERR,ERROR,*999)
                  CASE(SOLVER_DAE_EULER_BACKWARD)
                    CALL SOLVER_DAE_EULER_BACKWARD_FINALISE(EULER_DAE_SOLVER%BACKWARD_EULER_SOLVER,ERR,ERROR,*999)
                  CASE(SOLVER_DAE_EULER_IMPROVED)
                    CALL SOLVER_DAE_EULER_IMPROVED_FINALISE(EULER_DAE_SOLVER%IMPROVED_EULER_SOLVER,ERR,ERROR,*999)
                  CASE DEFAULT
                    LOCAL_ERROR="The Euler differential-algebraic equation solver type of "// &
                      & TRIM(NUMBER_TO_VSTRING(EULER_DAE_SOLVER%EULER_TYPE,"*",ERR,ERROR))//" is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT
                  EULER_DAE_SOLVER%EULER_TYPE=DAE_EULER_TYPE
                ENDIF
              ELSE
                CALL FLAG_ERROR("The differential-algebraic equation solver Euler solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver differential-algebraic equation solver is not an Euler differential-algebraic "// &
                & "equation solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a differential-algebraic equation solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_EULER_SOLVER_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_DAE_EULER_SOLVER_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_EULER_SOLVER_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_EULER_SOLVER_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Finalise a differential-algebraic equation solver and deallocate all memory
  SUBROUTINE SOLVER_DAE_FINALISE(DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer the differential-algebraic equation solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DAE_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      CALL SOLVER_DAE_EULER_FINALISE(DAE_SOLVER%EULER_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_DAE_CRANK_NICHOLSON_FINALISE(DAE_SOLVER%CRANK_NICHOLSON_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_DAE_RUNGE_KUTTA_FINALISE(DAE_SOLVER%RUNGE_KUTTA_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_DAE_ADAMS_MOULTON_FINALISE(DAE_SOLVER%ADAMS_MOULTON_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_DAE_BDF_FINALISE(DAE_SOLVER%BDF_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_DAE_RUSH_LARSON_FINALISE(DAE_SOLVER%RUSH_LARSON_SOLVER,ERR,ERROR,*999)
      DEALLOCATE(DAE_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a differential-algebraic equation solver for a solver
  SUBROUTINE SOLVER_DAE_INITIALISE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to initialise the differential-algebraic equation solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    CALL ENTERS("SOLVER_DAE_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(ASSOCIATED(SOLVER%DAE_SOLVER)) THEN
        CALL FLAG_ERROR("Differential-algebraic equation solver is already associated for this solver.",ERR,ERROR,*998)
      ELSE
        !Allocate the differential-algebraic equation solver
        ALLOCATE(SOLVER%DAE_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver differential-algebraic equation solver.",ERR,ERROR,*999)
        !Initialise
        SOLVER%DAE_SOLVER%SOLVER=>SOLVER
        SOLVER%DAE_SOLVER%DAE_TYPE=0
        SOLVER%DAE_SOLVER%DAE_SOLVE_TYPE=0
        SOLVER%DAE_SOLVER%START_TIME=0.0_DP
        SOLVER%DAE_SOLVER%END_TIME=0.1_DP
        SOLVER%DAE_SOLVER%INITIAL_STEP=0.1_DP
        NULLIFY(SOLVER%DAE_SOLVER%EULER_SOLVER)
        NULLIFY(SOLVER%DAE_SOLVER%CRANK_NICHOLSON_SOLVER)
        NULLIFY(SOLVER%DAE_SOLVER%RUNGE_KUTTA_SOLVER)
        NULLIFY(SOLVER%DAE_SOLVER%ADAMS_MOULTON_SOLVER)
        NULLIFY(SOLVER%DAE_SOLVER%BDF_SOLVER)
        NULLIFY(SOLVER%DAE_SOLVER%RUSH_LARSON_SOLVER)
        !Default to an Euler differential equation solver
        CALL SOLVER_DAE_EULER_INITIALISE(SOLVER%DAE_SOLVER,ERR,ERROR,*999)
        SOLVER%DAE_SOLVER%DAE_SOLVE_TYPE=SOLVER_DAE_EULER
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_DAE_INITIALISE")
    RETURN
999 CALL SOLVER_DAE_FINALISE(SOLVER%DAE_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_DAE_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_LIBRARY_TYPE_GET(DAE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer the differential-algebraic equation solver to get the library type for
    INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On return, the type of library used for the differential-algebraic equation solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(ADAMS_MOULTON_DAE_SOLVER_TYPE), POINTER :: ADAMS_MOULTON_DAE_SOLVER
    TYPE(BDF_DAE_SOLVER_TYPE), POINTER :: BDF_DAE_SOLVER
    TYPE(CRANK_NICHOLSON_DAE_SOLVER_TYPE), POINTER :: CRANK_NICHOLSON_DAE_SOLVER
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_DAE_SOLVER
    TYPE(RUNGE_KUTTA_DAE_SOLVER_TYPE), POINTER :: RUNGE_KUTTA_DAE_SOLVER
    TYPE(RUSH_LARSON_DAE_SOLVER_TYPE), POINTER :: RUSH_LARSON_DAE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_DAE_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      SELECT CASE(DAE_SOLVER%DAE_SOLVE_TYPE)
      CASE(SOLVER_DAE_EULER)
        EULER_DAE_SOLVER=>DAE_SOLVER%EULER_SOLVER
        IF(ASSOCIATED(EULER_DAE_SOLVER)) THEN
          CALL SOLVER_DAE_EULER_LIBRARY_TYPE_GET(EULER_DAE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Euler differential-algebraic solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_CRANK_NICHOLSON)
        CRANK_NICHOLSON_DAE_SOLVER=>DAE_SOLVER%CRANK_NICHOLSON_SOLVER
        IF(ASSOCIATED(CRANK_NICHOLSON_DAE_SOLVER)) THEN
          SOLVER_LIBRARY_TYPE=CRANK_NICHOLSON_DAE_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("The Crank-Nicholson differntial-algebraic equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_RUNGE_KUTTA)
        RUNGE_KUTTA_DAE_SOLVER=>DAE_SOLVER%RUNGE_KUTTA_SOLVER
        IF(ASSOCIATED(RUNGE_KUTTA_DAE_SOLVER)) THEN
          SOLVER_LIBRARY_TYPE=RUNGE_KUTTA_DAE_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("The Runge-Kutta differntial-algebraic equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_ADAMS_MOULTON)
        ADAMS_MOULTON_DAE_SOLVER=>DAE_SOLVER%ADAMS_MOULTON_SOLVER
        IF(ASSOCIATED(ADAMS_MOULTON_DAE_SOLVER)) THEN
          SOLVER_LIBRARY_TYPE=ADAMS_MOULTON_DAE_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("The Adams-Moulton differntial-algebraic equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_BDF)
        BDF_DAE_SOLVER=>DAE_SOLVER%BDF_SOLVER
        IF(ASSOCIATED(BDF_DAE_SOLVER)) THEN
          SOLVER_LIBRARY_TYPE=BDF_DAE_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("The BDF differntial-algebraic equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_RUSH_LARSON)
        RUSH_LARSON_DAE_SOLVER=>DAE_SOLVER%RUSH_LARSON_SOLVER
        IF(ASSOCIATED(RUSH_LARSON_DAE_SOLVER)) THEN
          SOLVER_LIBRARY_TYPE=RUSH_LARSON_DAE_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("The Rush-Larson differntial-algebraic equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The differential-algebraic equations solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(DAE_SOLVER%DAE_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("DAE solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DAE_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_DAE_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library to use for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_LIBRARY_TYPE_SET(DAE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer the differential-algebraic equation solver to set the library type for
    INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library for the differential-algebraic equation solver to set \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(ADAMS_MOULTON_DAE_SOLVER_TYPE), POINTER :: ADAMS_MOULTON_DAE_SOLVER
    TYPE(BACKWARD_EULER_DAE_SOLVER_TYPE), POINTER :: BACKWARD_EULER_DAE_SOLVER
    TYPE(BDF_DAE_SOLVER_TYPE), POINTER :: BDF_DAE_SOLVER
    TYPE(CRANK_NICHOLSON_DAE_SOLVER_TYPE), POINTER :: CRANK_NICHOLSON_DAE_SOLVER
    TYPE(EULER_DAE_SOLVER_TYPE), POINTER :: EULER_DAE_SOLVER
    TYPE(FORWARD_EULER_DAE_SOLVER_TYPE), POINTER :: FORWARD_EULER_DAE_SOLVER
    TYPE(IMPROVED_EULER_DAE_SOLVER_TYPE), POINTER :: IMPROVED_EULER_DAE_SOLVER
    TYPE(RUNGE_KUTTA_DAE_SOLVER_TYPE), POINTER :: RUNGE_KUTTA_DAE_SOLVER
    TYPE(RUSH_LARSON_DAE_SOLVER_TYPE), POINTER :: RUSH_LARSON_DAE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_DAE_LIBRARY_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      SELECT CASE(DAE_SOLVER%DAE_SOLVE_TYPE)
      CASE(SOLVER_DAE_EULER)
        EULER_DAE_SOLVER=>DAE_SOLVER%EULER_SOLVER
        IF(ASSOCIATED(EULER_DAE_SOLVER)) THEN
          SELECT CASE(EULER_DAE_SOLVER%EULER_TYPE)
          CASE(SOLVER_DAE_EULER_FORWARD)
            FORWARD_EULER_DAE_SOLVER=>EULER_DAE_SOLVER%FORWARD_EULER_SOLVER
            IF(ASSOCIATED(FORWARD_EULER_DAE_SOLVER)) THEN
              SELECT CASE(SOLVER_LIBRARY_TYPE)
              CASE(SOLVER_CMISS_LIBRARY)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(SOLVER_PETSC_LIBRARY)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            ELSE
              CALL FLAG_ERROR("The forward Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
            ENDIF
          CASE(SOLVER_DAE_EULER_BACKWARD)
            BACKWARD_EULER_DAE_SOLVER=>EULER_DAE_SOLVER%BACKWARD_EULER_SOLVER
            IF(ASSOCIATED(BACKWARD_EULER_DAE_SOLVER)) THEN
              SELECT CASE(SOLVER_LIBRARY_TYPE)
              CASE(SOLVER_CMISS_LIBRARY)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(SOLVER_PETSC_LIBRARY)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            ELSE
              CALL FLAG_ERROR("The backward Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
            ENDIF
          CASE(SOLVER_DAE_EULER_IMPROVED)
            IMPROVED_EULER_DAE_SOLVER=>EULER_DAE_SOLVER%IMPROVED_EULER_SOLVER
            IF(ASSOCIATED(IMPROVED_EULER_DAE_SOLVER)) THEN
              SELECT CASE(SOLVER_LIBRARY_TYPE)
              CASE(SOLVER_CMISS_LIBRARY)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(SOLVER_PETSC_LIBRARY)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
                  & " is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            ELSE
              CALL FLAG_ERROR("The improved Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
            ENDIF
          CASE DEFAULT
            LOCAL_ERROR="The Euler differential-algebraic equations solver type of "// &
              & TRIM(NUMBER_TO_VSTRING(EULER_DAE_SOLVER%EULER_TYPE,"*",ERR,ERROR))//" is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("The Euler differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_CRANK_NICHOLSON)
        CRANK_NICHOLSON_DAE_SOLVER=>DAE_SOLVER%CRANK_NICHOLSON_SOLVER
        IF(ASSOCIATED(CRANK_NICHOLSON_DAE_SOLVER)) THEN
          SELECT CASE(SOLVER_LIBRARY_TYPE)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
              & " is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("The Crank-Nicholson differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_RUNGE_KUTTA)
        RUNGE_KUTTA_DAE_SOLVER=>DAE_SOLVER%RUNGE_KUTTA_SOLVER
        IF(ASSOCIATED(RUNGE_KUTTA_DAE_SOLVER)) THEN
          SELECT CASE(SOLVER_LIBRARY_TYPE)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
              & " is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("The Runge-Kutta differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_ADAMS_MOULTON)
        ADAMS_MOULTON_DAE_SOLVER=>DAE_SOLVER%ADAMS_MOULTON_SOLVER
        IF(ASSOCIATED(ADAMS_MOULTON_DAE_SOLVER)) THEN
          SELECT CASE(SOLVER_LIBRARY_TYPE)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
              & " is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("The Adams-Moulton differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_BDF)
        BDF_DAE_SOLVER=>DAE_SOLVER%BDF_SOLVER
        IF(ASSOCIATED(BDF_DAE_SOLVER)) THEN
          SELECT CASE(SOLVER_LIBRARY_TYPE)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
              & " is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("The BDF differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_RUSH_LARSON)
        RUSH_LARSON_DAE_SOLVER=>DAE_SOLVER%RUSH_LARSON_SOLVER
        IF(ASSOCIATED(RUSH_LARSON_DAE_SOLVER)) THEN
          SELECT CASE(SOLVER_LIBRARY_TYPE)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
              & " is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("The Rush-Larson differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The differential-algebraic equations solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(DAE_SOLVER%DAE_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("DAE solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DAE_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_DAE_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_LIBRARY_TYPE_SET")
    RETURN 1
    
  END SUBROUTINE SOLVER_DAE_LIBRARY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Finalise a BDF differential-algebraic equation solver and deallocate all memory.
  SUBROUTINE SOLVER_DAE_BDF_FINALISE(BDF_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(BDF_DAE_SOLVER_TYPE), POINTER :: BDF_SOLVER !<A pointer the BDF differential-algebraic equation solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("SOLVER_DAE_BDF_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(BDF_SOLVER)) THEN
      DEALLOCATE(BDF_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_BDF_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_BDF_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_BDF_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_BDF_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a BDF solver for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_BDF_INITIALISE(DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer the differential-algebraic equation solver to initialise a BDF solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_DAE_BDF_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      IF(ASSOCIATED(DAE_SOLVER%BDF_SOLVER)) THEN
        CALL FLAG_ERROR("BDF solver is already associated for this differential-algebraic equation solver.",ERR,ERROR,*998)
      ELSE
        !Allocate the BDF solver
        ALLOCATE(DAE_SOLVER%BDF_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate BDF solver.",ERR,ERROR,*999)
        !Initialise
        DAE_SOLVER%BDF_SOLVER%DAE_SOLVER=>DAE_SOLVER
        DAE_SOLVER%BDF_SOLVER%SOLVER_LIBRARY=0
        !Defaults
      ENDIF      
    ELSE
      CALL FLAG_ERROR("Differential-algebraic equation solver is not associated.",ERR,ERROR,*998)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_BDF_INITIALISE")
    RETURN
999 CALL SOLVER_DAE_BDF_FINALISE(DAE_SOLVER%BDF_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_DAE_BDF_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_BDF_INITIALISE")
    RETURN 1
    
  END SUBROUTINE SOLVER_DAE_BDF_INITIALISE

  !
  !================================================================================================================================
  !

  !>Solve using a BDF differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_BDF_SOLVE(BDF_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(BDF_DAE_SOLVER_TYPE), POINTER :: BDF_SOLVER !<A pointer the BDF differential-algebraic equation solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DAE_BDF_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(BDF_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("BDF differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_BDF_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_BDF_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_BDF_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_BDF_SOLVE
  
  !
  !================================================================================================================================
  !

  !>Finalise a Crank-Nicholson differential-algebraic equation solver and deallocate all memory.
  SUBROUTINE SOLVER_DAE_CRANK_NICHOLSON_FINALISE(CRANK_NICHOLSON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(CRANK_NICHOLSON_DAE_SOLVER_TYPE), POINTER :: CRANK_NICHOLSON_SOLVER !<A pointer the Crank-Nicholson differential-algebraic equation solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("SOLVER_DAE_CRANK_NICHOLSON_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(CRANK_NICHOLSON_SOLVER)) THEN
      DEALLOCATE(CRANK_NICHOLSON_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_CRANK_NICHOLSON_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_CRANK_NICHOLSON_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_RUNTE_KUTTA_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_CRANK_NICHOLSON_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a Crank-Nicholson solver for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_CRANK_NICHOLSON_INITIALISE(DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer the differential-algebraic equation solver to initialise a Crank-Nicholson solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_DAE_CRANK_NICHOLSON_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      IF(ASSOCIATED(DAE_SOLVER%CRANK_NICHOLSON_SOLVER)) THEN
        CALL FLAG_ERROR("Crank-Nicholson solver is already associated for this differential-algebraic equation solver.", &
          & ERR,ERROR,*998)
      ELSE
        !Allocate the Runge-Kutta solver
        ALLOCATE(DAE_SOLVER%CRANK_NICHOLSON_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate Crank-Nicholson solver.",ERR,ERROR,*999)
        !Initialise
        DAE_SOLVER%CRANK_NICHOLSON_SOLVER%DAE_SOLVER=>DAE_SOLVER
        DAE_SOLVER%CRANK_NICHOLSON_SOLVER%SOLVER_LIBRARY=0
        !Defaults
      ENDIF      
    ELSE
      CALL FLAG_ERROR("Differential-algebraic equation solver is not associated.",ERR,ERROR,*998)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_CRANK_NICHOLSON_INITIALISE")
    RETURN
999 CALL SOLVER_DAE_CRANK_NICHOLSON_FINALISE(DAE_SOLVER%CRANK_NICHOLSON_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_DAE_CRANK_NICHOLSON_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_CRANK_NICHOLSON_INITIALISE")
    RETURN 1
    
  END SUBROUTINE SOLVER_DAE_CRANK_NICHOLSON_INITIALISE

  !
  !================================================================================================================================
  !

  !>Solve using a Crank-Nicholson differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_CRANK_NICHOLSON_SOLVE(CRANK_NICHOLSON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(CRANK_NICHOLSON_DAE_SOLVER_TYPE), POINTER :: CRANK_NICHOLSON_SOLVER !<A pointer the Crank-Nicholson differential-algebraic equation solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DAE_CRANK_NICHOLSON_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(CRANK_NICHOLSON_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Crank-Nicholson differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_CRANK_NICHOLSON_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_CRANK_NICHOLSON_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_CRANK_NICHOLSON_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_CRANK_NICHOLSON_SOLVE
  
  !
  !================================================================================================================================
  !

  !>Finalise a Runge-Kutta differential-algebraic equation solver and deallocate all memory.
  SUBROUTINE SOLVER_DAE_RUNGE_KUTTA_FINALISE(RUNGE_KUTTA_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(RUNGE_KUTTA_DAE_SOLVER_TYPE), POINTER :: RUNGE_KUTTA_SOLVER !<A pointer the Runge-Kutta differential-algebraic equation solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("SOLVER_DAE_RUNGE_KUTTA_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(RUNGE_KUTTA_SOLVER)) THEN
      DEALLOCATE(RUNGE_KUTTA_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_RUNGE_KUTTA_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_RUNGE_KUTTA_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_RUNTE_KUTTA_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_RUNGE_KUTTA_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a Runge-Kutta solver for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_RUNGE_KUTTA_INITIALISE(DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer the differential-algebraic equation solver to initialise a Runge-Kutta solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_DAE_RUNGE_KUTTA_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      IF(ASSOCIATED(DAE_SOLVER%RUNGE_KUTTA_SOLVER)) THEN
        CALL FLAG_ERROR("Runge-Kutta solver is already associated for this differential-algebraic equation solver.",ERR,ERROR,*998)
      ELSE
        !Allocate the Runge-Kutta solver
        ALLOCATE(DAE_SOLVER%RUNGE_KUTTA_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate Runge-Kutta solver.",ERR,ERROR,*999)
        !Initialise
        DAE_SOLVER%RUNGE_KUTTA_SOLVER%DAE_SOLVER=>DAE_SOLVER
        DAE_SOLVER%RUNGE_KUTTA_SOLVER%SOLVER_LIBRARY=0
        !Defaults
      ENDIF      
    ELSE
      CALL FLAG_ERROR("Differential-algebraic equation solver is not associated.",ERR,ERROR,*998)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_RUNGE_KUTTA_INITIALISE")
    RETURN
999 CALL SOLVER_DAE_RUNGE_KUTTA_FINALISE(DAE_SOLVER%RUNGE_KUTTA_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_DAE_RUNGE_KUTTA_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_RUNGE_KUTTA_INITIALISE")
    RETURN 1
    
  END SUBROUTINE SOLVER_DAE_RUNGE_KUTTA_INITIALISE

  !
  !================================================================================================================================
  !

  !>Solve using a Runge-Kutta differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_RUNGE_KUTTA_SOLVE(RUNGE_KUTTA_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(RUNGE_KUTTA_DAE_SOLVER_TYPE), POINTER :: RUNGE_KUTTA_SOLVER !<A pointer the Runge-Kutta differential-algebraic equation solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DAE_RUNGE_KUTTA_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(RUNGE_KUTTA_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Runge-Kutta differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_RUNGE_KUTTA_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_RUNGE_KUTTA_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_RUNGE_KUTTA_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_RUNGE_KUTTA_SOLVE
  
  !
  !================================================================================================================================
  !

  !>Finalise a Rush-Larson differential-algebraic equation solver and deallocate all memory.
  SUBROUTINE SOLVER_DAE_RUSH_LARSON_FINALISE(RUSH_LARSON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(RUSH_LARSON_DAE_SOLVER_TYPE), POINTER :: RUSH_LARSON_SOLVER !<A pointer the Rush-Larson differential-algebraic equation solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
     
    CALL ENTERS("SOLVER_DAE_RUSH_LARSON_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(RUSH_LARSON_SOLVER)) THEN
      DEALLOCATE(RUSH_LARSON_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_RUSH_LARSON_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_RUSH_LARSON_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_RUSH_LARSON_FINALISE")
    RETURN 1
    
  END SUBROUTINE SOLVER_DAE_RUSH_LARSON_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise an Rush-Larson solver for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_RUSH_LARSON_INITIALISE(DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer the differential-algebraic equation solver to initialise a Rush-Larson solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_DAE_RUSH_LARSON_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      IF(ASSOCIATED(DAE_SOLVER%RUSH_LARSON_SOLVER)) THEN
        CALL FLAG_ERROR("Rush-Larson solver is already associated for this differential-algebraic equation solver.",ERR,ERROR,*998)
      ELSE
        !Allocate the Rush-Larson solver
        ALLOCATE(DAE_SOLVER%RUSH_LARSON_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate Rush-Larson solver.",ERR,ERROR,*999)
        !Initialise
        DAE_SOLVER%RUSH_LARSON_SOLVER%DAE_SOLVER=>DAE_SOLVER
        DAE_SOLVER%RUSH_LARSON_SOLVER%SOLVER_LIBRARY=0
        !Defaults
      ENDIF      
    ELSE
      CALL FLAG_ERROR("Differential-algebraic equation solver is not associated.",ERR,ERROR,*998)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_RUSH_LARSON_INITIALISE")
    RETURN
999 CALL SOLVER_DAE_RUSH_LARSON_FINALISE(DAE_SOLVER%RUSH_LARSON_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_DAE_RUSH_LARSON_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_RUSH_LARSON_INITIALISE")
    RETURN 1
    
  END SUBROUTINE SOLVER_DAE_RUSH_LARSON_INITIALISE

  !
  !================================================================================================================================
  !

  !>Solve using a Rush-Larson differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_RUSH_LARSON_SOLVE(RUSH_LARSON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(RUSH_LARSON_DAE_SOLVER_TYPE), POINTER :: RUSH_LARSON_SOLVER !<A pointer the Rush-Larson differential-algebraic equation solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DAE_RUSH_LARSON_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(RUSH_LARSON_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Rush-Larson differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_RUSH_LARSON_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_RUSH_LARSON_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_RUSH_LARSON_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_RUSH_LARSON_SOLVE

  !
  !================================================================================================================================
  !

  !>Solve a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_SOLVE(DAE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer the differential-algebraic equation solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_DAE_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
      SELECT CASE(DAE_SOLVER%DAE_SOLVE_TYPE)
      CASE(SOLVER_DAE_EULER)
        CALL SOLVER_DAE_EULER_SOLVE(DAE_SOLVER%EULER_SOLVER,ERR,ERROR,*999)
      CASE(SOLVER_DAE_CRANK_NICHOLSON)
        CALL SOLVER_DAE_CRANK_NICHOLSON_SOLVE(DAE_SOLVER%CRANK_NICHOLSON_SOLVER,ERR,ERROR,*999)
      CASE(SOLVER_DAE_RUNGE_KUTTA)
        CALL SOLVER_DAE_RUNGE_KUTTA_SOLVE(DAE_SOLVER%RUNGE_KUTTA_SOLVER,ERR,ERROR,*999)
      CASE(SOLVER_DAE_ADAMS_MOULTON)
        CALL SOLVER_DAE_ADAMS_MOULTON_SOLVE(DAE_SOLVER%ADAMS_MOULTON_SOLVER,ERR,ERROR,*999)        
      CASE(SOLVER_DAE_BDF)
        CALL SOLVER_DAE_BDF_SOLVE(DAE_SOLVER%BDF_SOLVER,ERR,ERROR,*999)
      CASE(SOLVER_DAE_RUSH_LARSON)
        CALL SOLVER_DAE_RUSH_LARSON_SOLVE(DAE_SOLVER%RUSH_LARSON_SOLVER,ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The differential-algebraic equation solver solve type of "// &
          & TRIM(NUMBER_TO_VSTRING(DAE_SOLVER%DAE_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_DAE_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_SOLVE

  !
  !================================================================================================================================
  !
  
  !>Returns the solve type for an differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_SOLVER_TYPE_GET(SOLVER,DAE_SOLVE_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to get the differential-algebraic equation solver type for 
    INTEGER(INTG), INTENT(OUT) :: DAE_SOLVE_TYPE !<On return, the type of solver for the differential-algebraic equation to set \see SOLVER_ROUTINES_DAESolverTypes,SOLVER_ROUTINES.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER
     
    CALL ENTERS("SOLVER_DAE_SOLVER_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        IF(SOLVER%SOLVE_TYPE==SOLVER_DAE_TYPE) THEN
          DAE_SOLVER=>SOLVER%DAE_SOLVER
          IF(ASSOCIATED(DAE_SOLVER)) THEN
            DAE_SOLVE_TYPE=DAE_SOLVER%DAE_SOLVE_TYPE
         ELSE
            CALL FLAG_ERROR("The solver differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a differential-algebraic equation solver.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_SOLVER_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_DAE_SOLVER_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_SOLVER_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_SOLVER_TYPE_GET

  !
  !================================================================================================================================
  !
  
  !>Sets/changes the solve type for an differential-algebraic equation solver.
  SUBROUTINE SOLVER_DAE_SOLVER_TYPE_SET(SOLVER,DAE_SOLVE_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the differential-algebraic equation solver type for 
    INTEGER(INTG), INTENT(IN) :: DAE_SOLVE_TYPE !<The type of solver for the differential-algebraic equation to set \see SOLVER_ROUTINES_DAESolverTypes,SOLVER_ROUTINES.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
     
    CALL ENTERS("SOLVER_DAE_SOLVER_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_DAE_TYPE) THEN
          DAE_SOLVER=>SOLVER%DAE_SOLVER
          IF(ASSOCIATED(DAE_SOLVER)) THEN
            IF(DAE_SOLVE_TYPE/=DAE_SOLVER%DAE_SOLVE_TYPE) THEN
              !Intialise the new differential-algebraic equation solver type
              SELECT CASE(DAE_SOLVE_TYPE)
              CASE(SOLVER_DAE_EULER)
                CALL SOLVER_DAE_EULER_INITIALISE(DAE_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_DAE_CRANK_NICHOLSON)
                CALL SOLVER_DAE_CRANK_NICHOLSON_INITIALISE(DAE_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_DAE_RUNGE_KUTTA)
                CALL SOLVER_DAE_RUNGE_KUTTA_INITIALISE(DAE_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_DAE_ADAMS_MOULTON)
                CALL SOLVER_DAE_ADAMS_MOULTON_INITIALISE(DAE_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_DAE_BDF)
                CALL SOLVER_DAE_BDF_INITIALISE(DAE_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_DAE_RUSH_LARSON)
                CALL SOLVER_DAE_RUSH_LARSON_INITIALISE(DAE_SOLVER,ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The specified differential-algebraic equation solver type of "// &
                  & TRIM(NUMBER_TO_VSTRING(DAE_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
              !Finalise the old differential-algebraic equation solver type
              SELECT CASE(DAE_SOLVER%DAE_SOLVE_TYPE)
              CASE(SOLVER_DAE_EULER)
                CALL SOLVER_DAE_EULER_FINALISE(DAE_SOLVER%EULER_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_DAE_CRANK_NICHOLSON)
                CALL SOLVER_DAE_CRANK_NICHOLSON_FINALISE(DAE_SOLVER%CRANK_NICHOLSON_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_DAE_RUNGE_KUTTA)
                CALL SOLVER_DAE_RUNGE_KUTTA_FINALISE(DAE_SOLVER%RUNGE_KUTTA_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_DAE_ADAMS_MOULTON)
                CALL SOLVER_DAE_ADAMS_MOULTON_FINALISE(DAE_SOLVER%ADAMS_MOULTON_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_DAE_BDF)
                CALL SOLVER_DAE_BDF_FINALISE(DAE_SOLVER%BDF_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_DAE_RUSH_LARSON)
                CALL SOLVER_DAE_RUSH_LARSON_FINALISE(DAE_SOLVER%RUSH_LARSON_SOLVER,ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The differential-algebraic equation solve type of "// &
                  & TRIM(NUMBER_TO_VSTRING(DAE_SOLVER%DAE_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
              DAE_SOLVER%DAE_SOLVE_TYPE=DAE_SOLVE_TYPE
            ENDIF
         ELSE
            CALL FLAG_ERROR("The solver differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a differential-algebraic equation solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_SOLVER_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_DAE_SOLVER_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_SOLVER_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_SOLVER_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Set/change the times for a differential-algebraic equation solver
  SUBROUTINE SOLVER_DAE_TIMES_SET(SOLVER,START_TIME,END_TIME,INITIAL_STEP,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the differential-algebraic equation solver to set the times for
    REAL(DP), INTENT(IN) :: START_TIME !<The start time for the differential equation solver
    REAL(DP), INTENT(IN) :: END_TIME !<The end time for the differential equation solver
    REAL(DP), INTENT(IN) :: INITIAL_STEP !<The (initial) time step for the differential equation solver    
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_DAE_TIMES_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVE_TYPE==SOLVER_DAE_TYPE) THEN
        DAE_SOLVER=>SOLVER%DAE_SOLVER
        IF(ASSOCIATED(DAE_SOLVER)) THEN
          IF(END_TIME>START_TIME) THEN
            IF(ABS(INITIAL_STEP)<=ZERO_TOLERANCE) THEN
              LOCAL_ERROR="The specified initial step of "//TRIM(NUMBER_TO_VSTRING(INITIAL_STEP,"*",ERR,ERROR))// &
                & " is invalid. The initial step must not be zero."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            ELSE
              DAE_SOLVER%START_TIME=START_TIME
              DAE_SOLVER%END_TIME=END_TIME
              DAE_SOLVER%INITIAL_STEP=INITIAL_STEP
            ENDIF
          ELSE
            LOCAL_ERROR="The specified end time of "//TRIM(NUMBER_TO_VSTRING(END_TIME,"*",ERR,ERROR))// &
              & " is not > than the specified start time of "//TRIM(NUMBER_TO_VSTRING(START_TIME,"*",ERR,ERROR))//"."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("The solver is not a differential-algebraic equation solver.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DAE_TIMES_SET")
    RETURN
999 CALL ERRORS("SOLVER_DAE_TIMES_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_DAE_TIMES_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DAE_TIMES_SET

  !
  !================================================================================================================================
  !

  !>Destroys a solver
  SUBROUTINE SOLVER_DESTROY(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the solver to destroy
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_DESTROY")
    RETURN
999 CALL ERRORS("SOLVER_DESTROY",ERR,ERROR)    
    CALL EXITS("SOLVER_DESTROY")
    RETURN 1
   
  END SUBROUTINE SOLVER_DESTROY

  !
  !================================================================================================================================
  !

  !>Finishes the process of creating a dynamic solver 
  SUBROUTINE SOLVER_DYNAMIC_CREATE_FINISH(DYNAMIC_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER !<A pointer to the dynamic solver to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DYNAMIC_VARIABLE_TYPE,equations_matrix_idx,equations_set_idx,LINEAR_LIBRARY_TYPE,NONLINEAR_LIBRARY_TYPE
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MAPPING_DYNAMIC_TYPE), POINTER :: DYNAMIC_MAPPING
    TYPE(EQUATIONS_MAPPING_LINEAR_TYPE), POINTER :: LINEAR_MAPPING
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_DYNAMIC_TYPE), POINTER :: DYNAMIC_MATRICES
    TYPE(EQUATIONS_MATRICES_LINEAR_TYPE), POINTER :: LINEAR_MATRICES
    TYPE(EQUATIONS_MATRIX_TYPE), POINTER :: DAMPING_MATRIX,EQUATIONS_MATRIX,MASS_MATRIX
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD !, INDEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: DYNAMIC_VARIABLE,LINEAR_VARIABLE
    TYPE(SOLVER_TYPE), POINTER :: SOLVER,LINEAR_SOLVER,NONLINEAR_SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_DYNAMIC_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
      SOLVER=>DYNAMIC_SOLVER%SOLVER
      IF(ASSOCIATED(SOLVER)) THEN
        SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
        IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
          SELECT CASE(DYNAMIC_SOLVER%SOLVER_LIBRARY)
          CASE(SOLVER_CMISS_LIBRARY)
            !Create the parameter sets required for the solver
            SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
            IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
              SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
              IF(ASSOCIATED(SOLVER_MAPPING)) THEN
                !Initialise for explicit solve
                DYNAMIC_SOLVER%EXPLICIT=ABS(DYNAMIC_SOLVER%THETA(DYNAMIC_SOLVER%DEGREE))<ZERO_TOLERANCE
                !Loop over the equations set in the solver equations
                DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                  EQUATIONS=>SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)%EQUATIONS
                  IF(ASSOCIATED(EQUATIONS)) THEN
                    EQUATIONS_SET=>EQUATIONS%EQUATIONS_SET
                    IF(ASSOCIATED(EQUATIONS_SET)) THEN
                      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                        EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                        IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                          DYNAMIC_MAPPING=>EQUATIONS_MAPPING%DYNAMIC_MAPPING
                          IF(ASSOCIATED(DYNAMIC_MAPPING)) THEN
                            DYNAMIC_VARIABLE=>DYNAMIC_MAPPING%DYNAMIC_VARIABLE
                            DYNAMIC_VARIABLE_TYPE=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPE
                            IF(ASSOCIATED(DYNAMIC_VARIABLE)) THEN
                              SELECT CASE(DYNAMIC_SOLVER%DEGREE)
                              CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_PREVIOUS_VALUES_SET_TYPE)%PTR)) &
                                  & CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_PREVIOUS_VALUES_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                  & FIELD_MEAN_PREDICTED_DISPLACEMENT_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE( &
                                  & DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_MEAN_PREDICTED_DISPLACEMENT_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_INCREMENTAL_VALUES_SET_TYPE)% & 
                                  & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_INCREMENTAL_VALUES_SET_TYPE,ERR,ERROR,*999)
                                IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_NONLINEAR) THEN
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS% & 
                                    & SET_TYPE(FIELD_PREDICTED_DISPLACEMENT_SET_TYPE)% & 
                                    & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, & 
                                    & FIELD_PREDICTED_DISPLACEMENT_SET_TYPE,ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS% & 
                                    & SET_TYPE(FIELD_RESIDUAL_SET_TYPE)% & 
                                    & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, & 
                                    & FIELD_RESIDUAL_SET_TYPE,ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS% & 
                                    & SET_TYPE(FIELD_PREVIOUS_RESIDUAL_SET_TYPE)% & 
                                    & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, & 
                                    & FIELD_PREVIOUS_RESIDUAL_SET_TYPE,ERR,ERROR,*999)
                                END IF
                              CASE(SOLVER_DYNAMIC_SECOND_DEGREE)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_PREVIOUS_VALUES_SET_TYPE)%PTR)) &
                                  & CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_PREVIOUS_VALUES_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                  & FIELD_MEAN_PREDICTED_DISPLACEMENT_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE( &
                                  & DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_MEAN_PREDICTED_DISPLACEMENT_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_VELOCITY_VALUES_SET_TYPE)%PTR)) &
                                  & CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_VELOCITY_VALUES_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_PREVIOUS_VELOCITY_SET_TYPE)% &
                                  & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_PREVIOUS_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                  & FIELD_MEAN_PREDICTED_VELOCITY_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD, &
                                  & DYNAMIC_VARIABLE_TYPE,FIELD_MEAN_PREDICTED_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                                IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_NONLINEAR) THEN
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_INCREMENTAL_VALUES_SET_TYPE)% & 
                                    & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & FIELD_INCREMENTAL_VALUES_SET_TYPE,ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                    & FIELD_PREDICTED_DISPLACEMENT_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE( &
                                    & DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_PREDICTED_DISPLACEMENT_SET_TYPE,ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                    & FIELD_PREDICTED_VELOCITY_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD, &
                                    & DYNAMIC_VARIABLE_TYPE,FIELD_PREDICTED_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS% & 
                                    & SET_TYPE(FIELD_RESIDUAL_SET_TYPE)% & 
                                    & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, & 
                                    & FIELD_RESIDUAL_SET_TYPE,ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS% & 
                                    & SET_TYPE(FIELD_PREVIOUS_RESIDUAL_SET_TYPE)% & 
                                    & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, & 
                                    & FIELD_PREVIOUS_RESIDUAL_SET_TYPE,ERR,ERROR,*999)
                                END IF
                              CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_PREVIOUS_VALUES_SET_TYPE)%PTR)) &
                                  & CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_PREVIOUS_VALUES_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                  & FIELD_MEAN_PREDICTED_DISPLACEMENT_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE( &
                                  & DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_MEAN_PREDICTED_DISPLACEMENT_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_VELOCITY_VALUES_SET_TYPE)%PTR)) &
                                  & CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_VELOCITY_VALUES_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_PREVIOUS_VELOCITY_SET_TYPE)% &
                                  & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_PREVIOUS_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                  & FIELD_MEAN_PREDICTED_VELOCITY_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD, &
                                  & DYNAMIC_VARIABLE_TYPE,FIELD_MEAN_PREDICTED_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_ACCELERATION_VALUES_SET_TYPE)% &
                                  & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_ACCELERATION_VALUES_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_PREVIOUS_ACCELERATION_SET_TYPE)% &
                                  & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_PREVIOUS_ACCELERATION_SET_TYPE,ERR,ERROR,*999)
                                IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                  & FIELD_MEAN_PREDICTED_ACCELERATION_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE( &
                                  & DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_MEAN_PREDICTED_ACCELERATION_SET_TYPE, &
                                  & ERR,ERROR,*999)
                                IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_NONLINEAR) THEN
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE(FIELD_INCREMENTAL_VALUES_SET_TYPE)% & 
                                    & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & FIELD_INCREMENTAL_VALUES_SET_TYPE,ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                    & FIELD_PREDICTED_DISPLACEMENT_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE( &
                                    & DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_PREDICTED_DISPLACEMENT_SET_TYPE,ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                    & FIELD_PREDICTED_VELOCITY_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD, &
                                    & DYNAMIC_VARIABLE_TYPE,FIELD_PREDICTED_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS%SET_TYPE( &
                                    & FIELD_PREDICTED_ACCELERATION_SET_TYPE)%PTR)) CALL FIELD_PARAMETER_SET_CREATE( &
                                    & DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_PREDICTED_ACCELERATION_SET_TYPE, &
                                    & ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS% & 
                                    & SET_TYPE(FIELD_RESIDUAL_SET_TYPE)% & 
                                    & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, & 
                                    & FIELD_RESIDUAL_SET_TYPE,ERR,ERROR,*999)
                                  IF(.NOT.ASSOCIATED(DYNAMIC_VARIABLE%PARAMETER_SETS% & 
                                    & SET_TYPE(FIELD_PREVIOUS_RESIDUAL_SET_TYPE)% & 
                                    & PTR)) CALL FIELD_PARAMETER_SET_CREATE(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, & 
                                    & FIELD_PREVIOUS_RESIDUAL_SET_TYPE,ERR,ERROR,*999)
                                END IF
                              CASE DEFAULT
                                LOCAL_ERROR="The dynamic solver degree of "// &
                                  & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))//" is invalid."
                                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                              END SELECT
                              !Create the dynamic matrices temporary vector for matrix-vector products
                              EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                              IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                                DYNAMIC_MATRICES=>EQUATIONS_MATRICES%DYNAMIC_MATRICES
                                IF(ASSOCIATED(DYNAMIC_MATRICES)) THEN
                                  IF(.NOT.ASSOCIATED(DYNAMIC_MATRICES%TEMP_VECTOR)) THEN
                                    CALL DISTRIBUTED_VECTOR_CREATE_START(DYNAMIC_VARIABLE%DOMAIN_MAPPING, &
                                      & DYNAMIC_MATRICES%TEMP_VECTOR,ERR,ERROR,*999)
                                    CALL DISTRIBUTED_VECTOR_DATA_TYPE_SET(DYNAMIC_MATRICES%TEMP_VECTOR, &
                                      & DISTRIBUTED_MATRIX_VECTOR_DP_TYPE,ERR,ERROR,*999)
                                    CALL DISTRIBUTED_VECTOR_CREATE_FINISH(DYNAMIC_MATRICES%TEMP_VECTOR,ERR,ERROR,*999)
                                  ENDIF
                                  !Check to see if we have an explicit solve
                                  IF(ABS(DYNAMIC_SOLVER%THETA(DYNAMIC_SOLVER%DEGREE))<ZERO_TOLERANCE) THEN
                                    IF(DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER/=0) THEN
                                      DAMPING_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER)%PTR
                                      IF(ASSOCIATED(DAMPING_MATRIX)) THEN
                                        DYNAMIC_SOLVER%EXPLICIT=DYNAMIC_SOLVER%EXPLICIT.AND.DAMPING_MATRIX%LUMPED
                                      ELSE
                                        CALL FLAG_ERROR("Damping matrix is not associated.",ERR,ERROR,*999)
                                      ENDIF
                                    ENDIF
                                    IF(DYNAMIC_MAPPING%MASS_MATRIX_NUMBER/=0) THEN
                                      MASS_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%MASS_MATRIX_NUMBER)%PTR
                                      IF(ASSOCIATED(MASS_MATRIX)) THEN
                                        DYNAMIC_SOLVER%EXPLICIT=DYNAMIC_SOLVER%EXPLICIT.AND.MASS_MATRIX%LUMPED
                                      ELSE
                                        CALL FLAG_ERROR("Mass matrix is not associated.",ERR,ERROR,*999)
                                      ENDIF
                                    ENDIF
                                  ENDIF
                                ELSE
                                  CALL FLAG_ERROR("Equations matrices dynamic matrices are not associated.",ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                CALL FLAG_ERROR("Equations equations matrices is not associated.",ERR,ERROR,*999)
                              ENDIF
                              !Store initial field in FIELD_PREVIOUS_VALUES_SET_TYPE before applying BC to FIELD_VALUES_SET_TYPE
                              CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                                & FIELD_PREVIOUS_VALUES_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                            ELSE
                              CALL FLAG_ERROR("Dynamic mapping dynamic variable is not associated.",ERR,ERROR,*999)
                            ENDIF                            
                          ELSE
                            CALL FLAG_ERROR("Equations mapping dynamic mapping is not associated.",ERR,ERROR,*999)
                          ENDIF
                          LINEAR_MAPPING=>EQUATIONS_MAPPING%LINEAR_MAPPING
                          IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                            !If there are any linear matrices create temporary vector for matrix-vector products
                            EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                            IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                              LINEAR_MATRICES=>EQUATIONS_MATRICES%LINEAR_MATRICES
                              IF(ASSOCIATED(LINEAR_MATRICES)) THEN
                                DO equations_matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                                  EQUATIONS_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_idx)%PTR
                                  IF(ASSOCIATED(EQUATIONS_MATRIX)) THEN
                                    IF(.NOT.ASSOCIATED(EQUATIONS_MATRIX%TEMP_VECTOR)) THEN
                                      LINEAR_VARIABLE=>LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)%VARIABLE
                                      IF(ASSOCIATED(LINEAR_VARIABLE)) THEN
                                        CALL DISTRIBUTED_VECTOR_CREATE_START(LINEAR_VARIABLE%DOMAIN_MAPPING, &
                                          & EQUATIONS_MATRIX%TEMP_VECTOR,ERR,ERROR,*999)
                                        CALL DISTRIBUTED_VECTOR_DATA_TYPE_SET(EQUATIONS_MATRIX%TEMP_VECTOR, &
                                          & DISTRIBUTED_MATRIX_VECTOR_DP_TYPE,ERR,ERROR,*999)
                                        CALL DISTRIBUTED_VECTOR_CREATE_FINISH(EQUATIONS_MATRIX%TEMP_VECTOR,ERR,ERROR,*999)
                                      ELSE
                                        CALL FLAG_ERROR("Linear mapping linear variable is not associated.",ERR,ERROR,*999)
                                      ENDIF
                                    ENDIF
                                  ELSE
                                    CALL FLAG_ERROR("Equations matrix is not associated.",ERR,ERROR,*999)
                                  ENDIF
                                ENDDO !equations_matrix_idx
                              ELSE
                                CALL FLAG_ERROR("Equations matrices linear matrices is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              CALL FLAG_ERROR("Equations equations matrices is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Equations equations mapping is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        LOCAL_ERROR="Equations set dependent field is not associated for equations set index "// &
                          & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      LOCAL_ERROR="Equations equations set is not associated for equations set index "// &
                        & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    LOCAL_ERROR="Equations is not associated for equations set index "// &
                      & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  ENDIF
                ENDDO !equations_set_idx
                !Create the solver matrices and vectors
                IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_LINEAR) THEN
                  LINEAR_SOLVER=>DYNAMIC_SOLVER%LINEAR_SOLVER
                  IF(ASSOCIATED(LINEAR_SOLVER)) THEN
                    NULLIFY(SOLVER_MATRICES)
                    CALL SOLVER_MATRICES_CREATE_START(SOLVER_EQUATIONS,SOLVER_MATRICES,ERR,ERROR,*999)
                    CALL SOLVER_MATRICES_LIBRARY_TYPE_GET(LINEAR_SOLVER,LINEAR_LIBRARY_TYPE,ERR,ERROR,*999)
                    CALL SOLVER_MATRICES_LIBRARY_TYPE_SET(SOLVER_MATRICES,LINEAR_LIBRARY_TYPE,ERR,ERROR,*999)
                    IF(DYNAMIC_SOLVER%EXPLICIT) THEN
                      CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_DIAGONAL_STORAGE_TYPE/), &
                        & ERR,ERROR,*999)
                    ELSE
                      SELECT CASE(SOLVER_EQUATIONS%SPARSITY_TYPE)
                      CASE(SOLVER_SPARSE_MATRICES)
                        CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_COMPRESSED_ROW_STORAGE_TYPE/), &
                          & ERR,ERROR,*999)
                      CASE(SOLVER_FULL_MATRICES)
                        CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_BLOCK_STORAGE_TYPE/), &
                          & ERR,ERROR,*999)
                      CASE DEFAULT
                        LOCAL_ERROR="The specified solver equations sparsity type of "// &
                          & TRIM(NUMBER_TO_VSTRING(SOLVER_EQUATIONS%SPARSITY_TYPE,"*",ERR,ERROR))// &
                          & " is invalid."
                        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                      END SELECT
                    ENDIF
                    CALL SOLVER_MATRICES_CREATE_FINISH(SOLVER_MATRICES,ERR,ERROR,*999)
                    !Link linear solver
                    LINEAR_SOLVER%SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
                    !Finish the creation of the linear solver
                    CALL SOLVER_LINEAR_CREATE_FINISH(LINEAR_SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
                  ELSE
                    CALL FLAG_ERROR("Dynamic solver linear solver is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_NONLINEAR) THEN
                  NONLINEAR_SOLVER=>DYNAMIC_SOLVER%NONLINEAR_SOLVER
                  IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
                    NULLIFY(SOLVER_MATRICES)
                    CALL SOLVER_MATRICES_CREATE_START(SOLVER_EQUATIONS,SOLVER_MATRICES,ERR,ERROR,*999)
                    CALL SOLVER_MATRICES_LIBRARY_TYPE_GET(NONLINEAR_SOLVER,NONLINEAR_LIBRARY_TYPE,ERR,ERROR,*999)
                    CALL SOLVER_MATRICES_LIBRARY_TYPE_SET(SOLVER_MATRICES,NONLINEAR_LIBRARY_TYPE,ERR,ERROR,*999)
                    IF(DYNAMIC_SOLVER%EXPLICIT) THEN
                      CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_DIAGONAL_STORAGE_TYPE/), &
                        & ERR,ERROR,*999)
                    ELSE
                      SELECT CASE(SOLVER_EQUATIONS%SPARSITY_TYPE)
                      CASE(SOLVER_SPARSE_MATRICES)
                        CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_COMPRESSED_ROW_STORAGE_TYPE/), &
                          & ERR,ERROR,*999)
                      CASE(SOLVER_FULL_MATRICES)
                        CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_BLOCK_STORAGE_TYPE/), &
                          & ERR,ERROR,*999)
                      CASE DEFAULT
                        LOCAL_ERROR="The specified solver equations sparsity type of "// &
                          & TRIM(NUMBER_TO_VSTRING(SOLVER_EQUATIONS%SPARSITY_TYPE,"*",ERR,ERROR))// &
                          & " is invalid."
                        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                      END SELECT
                    ENDIF
                    CALL SOLVER_MATRICES_CREATE_FINISH(SOLVER_MATRICES,ERR,ERROR,*999)
                    !Link nonlinear solver
                    NONLINEAR_SOLVER%SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
                    !Finish the creation of the nonlinear solver
                    CALL SOLVER_NONLINEAR_CREATE_FINISH(NONLINEAR_SOLVER%NONLINEAR_SOLVER,ERR,ERROR,*999)
                  ELSE
                    CALL FLAG_ERROR("Dynamic solver linear solver is not associated.",ERR,ERROR,*999)
                  ENDIF
                ENDIF
              ELSE
                CALL FLAG_ERROR("Solver equations solver mapping is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
            ENDIF
          CASE(SOLVER_PETSC_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "// &
              & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))//" is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Dynamic solver solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_DYNAMIC_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_DYNAMIC_CREATE_FINISH")
    RETURN 1
   
  END SUBROUTINE SOLVER_DYNAMIC_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Returns the degree of the polynomial used to interpolate time for a dynamic solver.
  SUBROUTINE SOLVER_DYNAMIC_DEGREE_GET(SOLVER,DEGREE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the dynamic solver to get the degree for
    INTEGER(INTG), INTENT(OUT) :: DEGREE !<On return, the degree of the polynomial used for time interpolation in a dynamic solver \see SOLVER_ROUTINES_DynamicDegreeTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    
    CALL ENTERS("SOLVER_DYNAMIC_DEGREE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
          DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            DEGREE=DYNAMIC_SOLVER%DEGREE
          ELSE
            CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("The solver has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DYNAMIC_DEGREE_GET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_DEGREE_GET",ERR,ERROR)
    CALL EXITS("SOLVER_DYNAMIC_DEGREE_GET")
    RETURN 1
    
  END SUBROUTINE SOLVER_DYNAMIC_DEGREE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the degree of the polynomial used to interpolate time for a dynamic solver.
  SUBROUTINE SOLVER_DYNAMIC_DEGREE_SET(SOLVER,DEGREE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the dynamic solver to set the theta value for
    INTEGER(INTG), INTENT(IN) :: DEGREE !<The degree of the polynomial used for time interpolation in a dynamic solver \see SOLVER_ROUTINES_DynamicDegreeTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: degree_idx
    REAL(DP), ALLOCATABLE :: OLD_THETA(:)
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_DYNAMIC_DEGREE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("The solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
          DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            IF(DEGREE/=DYNAMIC_SOLVER%DEGREE) THEN
              IF(DEGREE>=DYNAMIC_SOLVER%ORDER) THEN
                SELECT CASE(DEGREE)
                CASE(SOLVER_DYNAMIC_FIRST_DEGREE,SOLVER_DYNAMIC_SECOND_DEGREE,SOLVER_DYNAMIC_THIRD_DEGREE)
                  ALLOCATE(OLD_THETA(DYNAMIC_SOLVER%DEGREE),STAT=ERR)
                  IF(ERR/=0) CALL FLAG_ERROR("Could not allocate old theta.",ERR,ERROR,*999)
                  OLD_THETA=DYNAMIC_SOLVER%THETA
                  IF(ALLOCATED(DYNAMIC_SOLVER%THETA)) DEALLOCATE(DYNAMIC_SOLVER%THETA)
                  ALLOCATE(DYNAMIC_SOLVER%THETA(DEGREE),STAT=ERR)
                  IF(ERR/=0) CALL FLAG_ERROR("Could not allocate theta.",ERR,ERROR,*999)
                  IF(DEGREE>DYNAMIC_SOLVER%DEGREE) THEN
                    DO degree_idx=1,DYNAMIC_SOLVER%DEGREE
                      DYNAMIC_SOLVER%THETA(degree_idx)=OLD_THETA(degree_idx)
                    ENDDO !degree_idx
                    DO degree_idx=DYNAMIC_SOLVER%DEGREE+1,DEGREE
                      DYNAMIC_SOLVER%THETA(degree_idx)=1.0_DP
                    ENDDO !degree_idx
                  ELSE
                    DO degree_idx=1,DEGREE
                      DYNAMIC_SOLVER%THETA(degree_idx)=OLD_THETA(degree_idx)
                    ENDDO !degree_idx
                  ENDIF
                  IF(ALLOCATED(OLD_THETA)) DEALLOCATE(OLD_THETA)
                  DYNAMIC_SOLVER%DEGREE=DEGREE
                CASE DEFAULT
                  LOCAL_ERROR="The specified degree of "//TRIM(NUMBER_TO_VSTRING(DEGREE,"*",ERR,ERROR))//" is invalid."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                END SELECT
              ELSE
                LOCAL_ERROR="Invalid dynamic solver setup. The specfied degree of "// &
                  & TRIM(NUMBER_TO_VSTRING(DEGREE,"*",ERR,ERROR))//" must be >= the current dynamic order of "// &
                  & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%ORDER,"*",ERR,ERROR))//"."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
            ENDIF
          ELSE
            CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DYNAMIC_DEGREE_SET")
    RETURN
999 IF(ALLOCATED(OLD_THETA)) DEALLOCATE(OLD_THETA)
    CALL ERRORS("SOLVER_DYNAMIC_DEGREE_SET",ERR,ERROR)
    CALL EXITS("SOLVER_DYNAMIC_DEGREE_SET")
    RETURN 1
  END SUBROUTINE SOLVER_DYNAMIC_DEGREE_SET

  !
  !================================================================================================================================
  !

  !>Finalise a dynamic solver and deallocates all memory
  SUBROUTINE SOLVER_DYNAMIC_FINALISE(DYNAMIC_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER !<A pointer the dynamic solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_DYNAMIC_FINALISE",ERR,ERROR,*999)
    IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
      IF(ALLOCATED(DYNAMIC_SOLVER%THETA)) THEN
!         CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Dynamic solver - theta = ",DYNAMIC_SOLVER%THETA(1), &
!         & ERR,ERROR,*999)
        DEALLOCATE(DYNAMIC_SOLVER%THETA)
      ENDIF
      CALL SOLVER_FINALISE(DYNAMIC_SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_FINALISE(DYNAMIC_SOLVER%NONLINEAR_SOLVER,ERR,ERROR,*999)
      DEALLOCATE(DYNAMIC_SOLVER)
    ENDIF
        
    CALL EXITS("SOLVER_DYNAMIC_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DYNAMIC_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DYNAMIC_FINALISE
 
  !
  !================================================================================================================================
  !

  !>Initialise a dynamic solver for a solver.
  SUBROUTINE SOLVER_DYNAMIC_INITIALISE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to initialise the dynamic solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER 


    CALL ENTERS("SOLVER_DYNAMIC_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(ASSOCIATED(SOLVER%DYNAMIC_SOLVER)) THEN
        CALL FLAG_ERROR("Dynamic solver is already associated for this solver.",ERR,ERROR,*999)
      ELSE
        !Allocate memory for dynamic solver and set default values (link solver later on)
        ALLOCATE(SOLVER%DYNAMIC_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver dynamic solver.",ERR,ERROR,*999)
        DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
        DYNAMIC_SOLVER%SOLVER=>SOLVER
        DYNAMIC_SOLVER%LINEARITY=SOLVER_DYNAMIC_LINEAR
        DYNAMIC_SOLVER%SOLVER_LIBRARY=SOLVER_CMISS_LIBRARY
        DYNAMIC_SOLVER%SOLVER_INITIALISED=.FALSE.
        DYNAMIC_SOLVER%ORDER=SOLVER_DYNAMIC_FIRST_ORDER
        DYNAMIC_SOLVER%DEGREE=SOLVER_DYNAMIC_FIRST_DEGREE
        DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_CRANK_NICHOLSON_SCHEME
        ALLOCATE(SOLVER%DYNAMIC_SOLVER%THETA(1),STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate theta.",ERR,ERROR,*999)
        DYNAMIC_SOLVER%THETA(1)=1.0_DP/2.0_DP
!         CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Dynamic solver - theta = ",DYNAMIC_SOLVER%THETA(1), &
!          & ERR,ERROR,*999)
        DYNAMIC_SOLVER%EXPLICIT=.FALSE.
        DYNAMIC_SOLVER%ALE=.TRUE. !this should be .FALSE. eventually and set by the user
        DYNAMIC_SOLVER%UPDATE_BC=.TRUE.  !this should be .FALSE. eventually and set by the user
        DYNAMIC_SOLVER%CURRENT_TIME=0.0_DP
        DYNAMIC_SOLVER%TIME_INCREMENT=0.01_DP
        !Allocate memory for dynamic linear and dynamic nonlinear solvers
        ALLOCATE(DYNAMIC_SOLVER%LINEAR_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver linear solver.",ERR,ERROR,*999)
        NULLIFY(DYNAMIC_SOLVER%LINEAR_SOLVER%SOLVERS)
        ALLOCATE(DYNAMIC_SOLVER%NONLINEAR_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver nonlinear solver.",ERR,ERROR,*999)
        NULLIFY(DYNAMIC_SOLVER%NONLINEAR_SOLVER%SOLVERS)

        !Set default values
        CALL SOLVER_INITIALISE_PTR(DYNAMIC_SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
        SOLVER%LINKED_SOLVER=>DYNAMIC_SOLVER%LINEAR_SOLVER
        DYNAMIC_SOLVER%LINEAR_SOLVER%LINKING_SOLVER=>SOLVER
        DYNAMIC_SOLVER%LINEAR_SOLVER%SOLVE_TYPE=SOLVER_LINEAR_TYPE
        CALL SOLVER_LINEAR_INITIALISE(DYNAMIC_SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_DYNAMIC_INITIALISE")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_DYNAMIC_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_DYNAMIC_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for a dynamic solver.
  SUBROUTINE SOLVER_DYNAMIC_LIBRARY_TYPE_GET(DYNAMIC_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER !<A pointer the dynamic solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On exit, the type of library used for the dynamic solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
 
    CALL ENTERS("SOLVER_DYNAMIC_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
      SOLVER_LIBRARY_TYPE=DYNAMIC_SOLVER%SOLVER_LIBRARY
    ELSE
      CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DYNAMIC_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_DYNAMIC_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DYNAMIC_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library to use for a dynamic solver.
  SUBROUTINE SOLVER_DYNAMIC_LIBRARY_TYPE_SET(DYNAMIC_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER !<A pointer the dynamic solver to get the library type for.
    INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library for the dynamic solver to set. \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_DYNAMIC_LIBRARY_TYPE_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
      SELECT CASE(SOLVER_LIBRARY_TYPE)
      CASE(SOLVER_CMISS_LIBRARY)
        DYNAMIC_SOLVER%SOLVER_LIBRARY=SOLVER_CMISS_LIBRARY
      CASE DEFAULT
        LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
          & " is invalid for a dynamic solver."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_DYNAMIC_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_DYNAMIC_LIBRARY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DYNAMIC_LIBRARY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Returns the linearity type for the dynamic solver. \see OPENCMISS::CMISSSolverDynamicLinearityTypeGet
  SUBROUTINE SOLVER_DYNAMIC_LINEARITY_TYPE_GET(SOLVER,LINEARITY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to get the dynamic linearity type for 
    INTEGER(INTG), INTENT(OUT) :: LINEARITY_TYPE !<On return, the type of linearity \see SOLVER_ROUTINES_EquationLinearityTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER !<A pointer the dynamic solver to finalise
  
    CALL ENTERS("SOLVER_DYNAMIC_LINEARITY_TYPE_GET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
        IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
          LINEARITY_TYPE=DYNAMIC_SOLVER%LINEARITY
        ELSE
          CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    END IF
    
    CALL EXITS("SOLVER_DYNAMIC_LINEARITY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_LINEARITY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_DYNAMIC_LINEARITY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DYNAMIC_LINEARITY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the linearity type for the dynamic solver. \see OPENCMISS::CMISSSolverDynamicLinearityTypeSet
  SUBROUTINE SOLVER_DYNAMIC_LINEARITY_TYPE_SET(SOLVER,LINEARITY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to initialise the dynamic solver for
    INTEGER(INTG), INTENT(IN) :: LINEARITY_TYPE !<The type of linearity to be set \see SOLVER_ROUTINES_EquationLinearityTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER !<A pointer the dynamic solver to finalise
    TYPE(VARYING_STRING) :: LOCAL_ERROR
  
    CALL ENTERS("SOLVER_DYNAMIC_LINEARITY_TYPE_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
        IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
          
          NULLIFY(DYNAMIC_SOLVER%LINEAR_SOLVER%SOLVERS)
          NULLIFY(DYNAMIC_SOLVER%NONLINEAR_SOLVER%SOLVERS)
          
          SELECT CASE(LINEARITY_TYPE)
          CASE(SOLVER_DYNAMIC_LINEAR)
            DYNAMIC_SOLVER%LINEARITY=SOLVER_DYNAMIC_LINEAR
            !                 !allocate new linked linear solver
            !                 ALLOCATE(DYNAMIC_SOLVER%LINEAR_SOLVER,STAT=ERR)
            !                 IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver linear solver.",ERR,ERROR,*999)
            CALL SOLVER_INITIALISE_PTR(DYNAMIC_SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
            SOLVER%LINKED_SOLVER=>DYNAMIC_SOLVER%LINEAR_SOLVER
            DYNAMIC_SOLVER%LINEAR_SOLVER%LINKING_SOLVER=>SOLVER
            DYNAMIC_SOLVER%LINEAR_SOLVER%SOLVE_TYPE=SOLVER_LINEAR_TYPE
            CALL SOLVER_LINEAR_INITIALISE(DYNAMIC_SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
          CASE(SOLVER_DYNAMIC_NONLINEAR)
            DYNAMIC_SOLVER%LINEARITY=SOLVER_DYNAMIC_NONLINEAR
            !                 !allocate new linked nonlinear solver
            !                 ALLOCATE(DYNAMIC_SOLVER%NONLINEAR_SOLVER,STAT=ERR)
            !                 IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver nonlinear solver.",ERR,ERROR,*999)
            CALL SOLVER_INITIALISE_PTR(DYNAMIC_SOLVER%NONLINEAR_SOLVER,ERR,ERROR,*999)
            SOLVER%LINKED_SOLVER=>DYNAMIC_SOLVER%NONLINEAR_SOLVER
            DYNAMIC_SOLVER%NONLINEAR_SOLVER%LINKING_SOLVER=>SOLVER
            DYNAMIC_SOLVER%NONLINEAR_SOLVER%SOLVE_TYPE=SOLVER_NONLINEAR_TYPE
            CALL SOLVER_NONLINEAR_INITIALISE(DYNAMIC_SOLVER%NONLINEAR_SOLVER,ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The specified solver equations linearity type of "// &
              & TRIM(NUMBER_TO_VSTRING(LINEARITY_TYPE,"*",ERR,ERROR))//" is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
          !           ENDIF
        ELSE
          CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    END IF
    
    CALL EXITS("SOLVER_DYNAMIC_LINEARITY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_LINEARITY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_DYNAMIC_LINEARITY_TYPE_SET")
    RETURN 1
    
  END SUBROUTINE SOLVER_DYNAMIC_LINEARITY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Returns the nonlinear solver associated with a dynamic solver
  SUBROUTINE SOLVER_DYNAMIC_NONLINEAR_SOLVER_GET(SOLVER,NONLINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the dynamic solver to get the linear solver for
    TYPE(SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER !<On exit, a pointer the linear solver linked to the dynamic solver. Must not be associated on entry
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER

    CALL ENTERS("SOLVER_DYNAMIC_NONLINEAR_SOLVER_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
        CALL FLAG_ERROR("Nonlinear solver is already associated.",ERR,ERROR,*999)
      ELSE
        NULLIFY(NONLINEAR_SOLVER)
        IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
          DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            NONLINEAR_SOLVER=>DYNAMIC_SOLVER%NONLINEAR_SOLVER
            IF(.NOT.ASSOCIATED(NONLINEAR_SOLVER)) CALL FLAG_ERROR("Dynamic solver nonlinear solver is not associated.", & 
              & ERR,ERROR,*999)
          ELSE
            CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_DYNAMIC_NONLINEAR_SOLVER_GET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_NONLINEAR_SOLVER_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_DYNAMIC_NONLINEAR_SOLVER_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DYNAMIC_NONLINEAR_SOLVER_GET

  !
  !================================================================================================================================
  !

  !>Returns the linear solver associated with a dynamic solver \see OPENCMISS::CMISSSolverDynamicLinearSolverGet
  SUBROUTINE SOLVER_DYNAMIC_LINEAR_SOLVER_GET(SOLVER,LINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the dynamic solver to get the linear solver for
    TYPE(SOLVER_TYPE), POINTER :: LINEAR_SOLVER !<On exit, a pointer the linear solver linked to the dynamic solver. Must not be associated on entry
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER

    CALL ENTERS("SOLVER_DYNAMIC_LINEAR_SOLVER_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(ASSOCIATED(LINEAR_SOLVER)) THEN
        CALL FLAG_ERROR("Linear solver is already associated.",ERR,ERROR,*999)
      ELSE
        NULLIFY(LINEAR_SOLVER)
        IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
          DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            LINEAR_SOLVER=>DYNAMIC_SOLVER%LINEAR_SOLVER
            IF(.NOT.ASSOCIATED(LINEAR_SOLVER)) CALL FLAG_ERROR("Dynamic solver linear solver is not associated.",ERR,ERROR,*999)
          ELSE
            CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_DYNAMIC_LINEAR_SOLVER_GET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_LINEAR_SOLVER_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_DYNAMIC_LINEAR_SOLVER_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_DYNAMIC_LINEAR_SOLVER_GET

  !
  !================================================================================================================================
  ! 

  !>Copies the current to previous time-step, calculates mean predicted values, predicted values and previous residual values.
  SUBROUTINE SOLVER_DYNAMIC_MEAN_PREDICTED_CALCULATE(SOLVER,ERR,ERROR,*)

    !Argument variableg
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the solver
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DYNAMIC_VARIABLE_TYPE,equations_set_idx,residual_variable_dof,equations_row_number
    REAL(DP) :: DELTA_T,FIRST_MEAN_PREDICTION_FACTOR, SECOND_MEAN_PREDICTION_FACTOR,THIRD_MEAN_PREDICTION_FACTOR
    REAL(DP) :: FIRST_PREDICTION_FACTOR, SECOND_PREDICTION_FACTOR,THIRD_PREDICTION_FACTOR,RESIDUAL_VALUE,ALPHA_FACTOR
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: RESIDUAL_VECTOR
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: NONLINEAR_MATRICES
    TYPE(EQUATIONS_MAPPING_NONLINEAR_TYPE), POINTER :: NONLINEAR_MAPPING
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MAPPING_DYNAMIC_TYPE), POINTER :: DYNAMIC_MAPPING
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(VARYING_STRING) :: LOCAL_ERROR
   
    CALL ENTERS("SOLVER_DYNAMIC_MEAN_PREDICTED_CALCULATE",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
      IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
        IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
          DELTA_T=DYNAMIC_SOLVER%TIME_INCREMENT
          SELECT CASE(DYNAMIC_SOLVER%DEGREE)
          CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
            FIRST_MEAN_PREDICTION_FACTOR=1.0_DP
            FIRST_PREDICTION_FACTOR=1.0_DP
          CASE(SOLVER_DYNAMIC_SECOND_DEGREE)
            FIRST_MEAN_PREDICTION_FACTOR=1.0_DP
            SECOND_MEAN_PREDICTION_FACTOR=DYNAMIC_SOLVER%THETA(1)*DELTA_T
            FIRST_PREDICTION_FACTOR=1.0_DP
            SECOND_PREDICTION_FACTOR=DELTA_T
          CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
            FIRST_MEAN_PREDICTION_FACTOR=1.0_DP
            SECOND_MEAN_PREDICTION_FACTOR=DYNAMIC_SOLVER%THETA(1)*DELTA_T
            THIRD_MEAN_PREDICTION_FACTOR=DYNAMIC_SOLVER%THETA(2)*DELTA_T*DELTA_T
            FIRST_PREDICTION_FACTOR=1.0_DP
            SECOND_PREDICTION_FACTOR=DELTA_T
            THIRD_PREDICTION_FACTOR=DELTA_T*DELTA_T
          CASE DEFAULT
            LOCAL_ERROR="The dynamic solver degree of "//TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))// &
              & " is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ENDIF
        SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
        IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
          SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
          IF(ASSOCIATED(SOLVER_MAPPING)) THEN
            IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
              !Copy current time to previous time
              DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                IF(ASSOCIATED(EQUATIONS_SET)) THEN
                  DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                  IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                    EQUATIONS=>EQUATIONS_SET%EQUATIONS
                    IF(ASSOCIATED(EQUATIONS)) THEN
                      EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                      IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                        DYNAMIC_MAPPING=>EQUATIONS_MAPPING%DYNAMIC_MAPPING
                        IF(ASSOCIATED(DYNAMIC_MAPPING)) THEN
                          DYNAMIC_VARIABLE_TYPE=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPE
                          SELECT CASE(DYNAMIC_SOLVER%DEGREE)
                          CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
!Commented out as FIELD_PREVIOUS_VALUES_SET_TYPE must not contain time-dependent boundary conditions
!FIELD_PREVIOUS_VALUES_SET_TYPE is now stored at the end of each time-step instead
!                             CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
!                               & FIELD_PREVIOUS_VALUES_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                          CASE(SOLVER_DYNAMIC_SECOND_DEGREE)
                            CALL FLAG_ERROR("Not checked yet.",ERR,ERROR,*999)
!                             CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
!                               & FIELD_PREVIOUS_VALUES_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                            CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_VELOCITY_VALUES_SET_TYPE, &
                              & FIELD_PREVIOUS_VELOCITY_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                          CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
                            CALL FLAG_ERROR("Not checked yet.",ERR,ERROR,*999)
!                             CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
!                               & FIELD_PREVIOUS_VALUES_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                            CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_VELOCITY_VALUES_SET_TYPE, &
                              & FIELD_PREVIOUS_VELOCITY_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                            CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                              & FIELD_ACCELERATION_VALUES_SET_TYPE,FIELD_PREVIOUS_ACCELERATION_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                          CASE DEFAULT
                            LOCAL_ERROR="The dynamic solver degree of "// &
                              & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))//" is invalid."
                            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)                        
                          END SELECT
                        ELSE
                          LOCAL_ERROR="Equations mapping dynamic mapping is not associated for equations set index number "// &
                            & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        LOCAL_ERROR="Equations equations mapping is not associated for equations set index number "// &
                          & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      LOCAL_ERROR="Equations set equations is not associated for equations set index number "// &
                        & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    LOCAL_ERROR="Equations set dependent field is not associated for equations set index number "// &
                      & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  ENDIF
                ELSE
                  LOCAL_ERROR="Equations set is not associated for equations set index number "// &
                    & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ENDDO !equations_set_idx
            ENDIF
            SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
            IF(ASSOCIATED(SOLVER_MATRICES)) THEN
              IF(DYNAMIC_SOLVER%SOLVER_INITIALISED.OR.(.NOT.DYNAMIC_SOLVER%SOLVER_INITIALISED.AND. &
                & ((DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_FIRST_ORDER.AND.DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_FIRST_DEGREE).OR. &
                & (DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_SECOND_ORDER.AND.DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_SECOND_DEGREE)))) &
                & THEN
                !Loop over the equations sets
                DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                  EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                  IF(ASSOCIATED(EQUATIONS_SET)) THEN
                    DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                    EQUATIONS=>EQUATIONS_SET%EQUATIONS
                    IF(ASSOCIATED(EQUATIONS)) THEN
                      EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                      IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                        EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                        IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                          DYNAMIC_MAPPING=>EQUATIONS_MAPPING%DYNAMIC_MAPPING
                          IF(ASSOCIATED(DYNAMIC_MAPPING)) THEN
                            DYNAMIC_VARIABLE_TYPE=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPE
                            IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_NONLINEAR) THEN
                              !Store the solver residual from the previous nonlinear solve (or initial values) 
                              NONLINEAR_MAPPING=>EQUATIONS_MAPPING%NONLINEAR_MAPPING
                              IF(ASSOCIATED(NONLINEAR_MAPPING)) THEN
                                NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
                                IF(ASSOCIATED(NONLINEAR_MATRICES)) THEN
! ! !                                 residual_variable_type=NONLINEAR_MAPPING%RESIDUAL_VARIABLE_TYPE
! ! !                                 RESIDUAL_VARIABLE=>NONLINEAR_MAPPING%RESIDUAL_VARIABLE
! ! !                                 RESIDUAL_DOMAIN_MAPPING=>RESIDUAL_VARIABLE%DOMAIN_MAPPING
                                  RESIDUAL_VECTOR=>NONLINEAR_MATRICES%RESIDUAL
                                  !Loop over the rows in the equations set
                                  DO equations_row_number=1,EQUATIONS_MAPPING%NUMBER_OF_ROWS
! ! !                                     IF(SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
! ! !                                       & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
! ! !                                       & NUMBER_OF_SOLVER_ROWS>0) THEN
                                      !Get the equations residual contribution
                                      CALL DISTRIBUTED_VECTOR_VALUES_GET(RESIDUAL_VECTOR,equations_row_number, &
                                        & RESIDUAL_VALUE,ERR,ERROR,*999)
                                      residual_variable_dof=NONLINEAR_MAPPING% & 
                                        & EQUATIONS_ROW_TO_RESIDUAL_DOF_MAP(equations_row_number)
                                      CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                        & FIELD_PREVIOUS_RESIDUAL_SET_TYPE,residual_variable_dof,RESIDUAL_VALUE, &
                                        & ERR,ERROR,*999)
! ! !                                     ENDIF
                                  ENDDO
                                ELSE
                                  CALL FLAG_ERROR("Equations matrices nonlinear matrices is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                CALL FLAG_ERROR("Equations mapping nonlinear mapping is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ENDIF
                            IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
                              !Calculate the mean predicted and predicted values for this dependent field
                              SELECT CASE(DYNAMIC_SOLVER%DEGREE)
                                CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
                                  !Copy the previous values to to the MEAN predicted values
                                  CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & FIELD_PREVIOUS_VALUES_SET_TYPE,FIELD_MEAN_PREDICTED_DISPLACEMENT_SET_TYPE,1.0_DP, & 
                                    & ERR,ERROR,*999)
                                  ALPHA_FACTOR=1.0_DP/DELTA_T
                                  !Generate update on alpha in FIELD_INCREMENTAL_VALUES_SET_TYPE by subtracting
                                  !FIELD_PREVIOUS_VALUES_SET_TYPE (without BC) from FIELD_VALUES_SET_TYPE (with new BC)
                                  CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & FIELD_VALUES_SET_TYPE,FIELD_INCREMENTAL_VALUES_SET_TYPE,ALPHA_FACTOR,ERR,ERROR,*999)
                                  CALL FIELD_PARAMETER_SETS_ADD(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & -ALPHA_FACTOR,FIELD_PREVIOUS_VALUES_SET_TYPE, &
                                    & FIELD_INCREMENTAL_VALUES_SET_TYPE,ERR,ERROR,*999)
                                  IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_NONLINEAR) THEN
                                    !Copy the previous values to to the predicted values
                                    CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & FIELD_PREVIOUS_VALUES_SET_TYPE,FIELD_PREDICTED_DISPLACEMENT_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                                  ENDIF
                                CASE(SOLVER_DYNAMIC_SECOND_DEGREE)
                                  CALL FIELD_PARAMETER_SETS_ADD(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & (/FIRST_MEAN_PREDICTION_FACTOR,SECOND_MEAN_PREDICTION_FACTOR/), &
                                    & (/FIELD_PREVIOUS_VALUES_SET_TYPE,FIELD_PREVIOUS_VELOCITY_SET_TYPE/), &
                                    & FIELD_MEAN_PREDICTED_DISPLACEMENT_SET_TYPE,ERR,ERROR,*999)
                                  CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & FIELD_PREVIOUS_VELOCITY_SET_TYPE,FIELD_MEAN_PREDICTED_VELOCITY_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                                  IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_NONLINEAR) THEN
                                    CALL FIELD_PARAMETER_SETS_ADD(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & (/FIRST_PREDICTION_FACTOR,SECOND_PREDICTION_FACTOR/), &
                                      & (/FIELD_PREVIOUS_VALUES_SET_TYPE,FIELD_PREVIOUS_VELOCITY_SET_TYPE/), &
                                      & FIELD_PREDICTED_DISPLACEMENT_SET_TYPE,ERR,ERROR,*999)
                                    CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & FIELD_PREVIOUS_VELOCITY_SET_TYPE,FIELD_PREDICTED_VELOCITY_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                                  END IF 
                                CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
                                  CALL FIELD_PARAMETER_SETS_ADD(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & (/FIRST_MEAN_PREDICTION_FACTOR,SECOND_MEAN_PREDICTION_FACTOR, &
                                    & THIRD_MEAN_PREDICTION_FACTOR/),(/FIELD_PREVIOUS_VALUES_SET_TYPE, &
                                    & FIELD_PREVIOUS_VELOCITY_SET_TYPE,FIELD_PREVIOUS_ACCELERATION_SET_TYPE/), &
                                    & FIELD_MEAN_PREDICTED_DISPLACEMENT_SET_TYPE,ERR,ERROR,*999)
                                  CALL FIELD_PARAMETER_SETS_ADD(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & (/FIRST_MEAN_PREDICTION_FACTOR,SECOND_MEAN_PREDICTION_FACTOR/), &
                                    & (/FIELD_PREVIOUS_VELOCITY_SET_TYPE,FIELD_PREVIOUS_ACCELERATION_SET_TYPE/), &
                                    & FIELD_MEAN_PREDICTED_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                                  CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & FIELD_PREVIOUS_ACCELERATION_SET_TYPE,FIELD_MEAN_PREDICTED_ACCELERATION_SET_TYPE,1.0_DP, &
                                    & ERR,ERROR,*999)
                                  IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_NONLINEAR) THEN
                                    CALL FIELD_PARAMETER_SETS_ADD(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & (/FIRST_PREDICTION_FACTOR,SECOND_PREDICTION_FACTOR, &
                                      & THIRD_PREDICTION_FACTOR/),(/FIELD_PREVIOUS_VALUES_SET_TYPE, &
                                      & FIELD_PREVIOUS_VELOCITY_SET_TYPE,FIELD_PREVIOUS_ACCELERATION_SET_TYPE/), &
                                      & FIELD_PREDICTED_DISPLACEMENT_SET_TYPE,ERR,ERROR,*999)
                                    CALL FIELD_PARAMETER_SETS_ADD(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & (/FIRST_PREDICTION_FACTOR,SECOND_PREDICTION_FACTOR/), &
                                      & (/FIELD_PREVIOUS_VELOCITY_SET_TYPE,FIELD_PREVIOUS_ACCELERATION_SET_TYPE/), &
                                      & FIELD_PREDICTED_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                                    CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & FIELD_PREVIOUS_ACCELERATION_SET_TYPE,FIELD_PREDICTED_ACCELERATION_SET_TYPE,1.0_DP, &
                                      & ERR,ERROR,*999)
                                  END IF 
                                CASE DEFAULT
                                  LOCAL_ERROR="The dynamic solver degree of "// &
                                    & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))//" is invalid."
                                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)                        
                              END SELECT
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("Equations mapping dynamic mapping is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Equations equations mapping is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        CALL FLAG_ERROR("Equations equations matrices is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      CALL FLAG_ERROR("Equations set equations is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
                  ENDIF
                ENDDO !equations_set_idx
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver solver matrices is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Solver equations solver mapping is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver dynamic solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("SOLVER_DYNAMIC_MEAN_PREDICTED_CALCULATE")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_MEAN_PREDICTED_CALCULATE",ERR,ERROR)
    CALL EXITS("SOLVER_DYNAMIC_MEAN_PREDICTED_CALCULATE")
    RETURN 1
  END SUBROUTINE SOLVER_DYNAMIC_MEAN_PREDICTED_CALCULATE

  !
  !================================================================================================================================
  !

  !>Monitors the differential-algebraic equations solve.
  SUBROUTINE SOLVER_TIME_STEPPING_MONITOR(DAE_SOLVER,STEPS,TIME,ERR,ERROR,*)

   !Argument variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER !<A pointer to the differential-algebraic equations solver to monitor
    INTEGER(INTG), INTENT(IN) :: STEPS !<The number of iterations
    REAL(DP), INTENT(IN) :: TIME !<The current time
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    
    CALL ENTERS("SOLVER_TIME_STEPPING_MONITOR",ERR,ERROR,*999)

    IF(ASSOCIATED(DAE_SOLVER)) THEN
        
      CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
      CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
      CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Differential-algebraic equations solve monitor: ",ERR,ERROR,*999)
      CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Number of steps = ",STEPS,ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Current time    = ",TIME,ERR,ERROR,*999)
      CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)      
        
    ELSE
      CALL FLAG_ERROR("Differential-algebraic equations solver is not associated.",ERR,ERROR,*999)
    ENDIF
     
    CALL EXITS("SOLVER_TIME_STEPPING_MONITOR")
    RETURN
999 CALL ERRORS("SOLVER_TIME_STEPPING_MONITOR",ERR,ERROR)
    CALL EXITS("SOLVER_TIME_STEPPING_MONITOR")
    RETURN 1
  END SUBROUTINE SOLVER_TIME_STEPPING_MONITOR

  !
  !================================================================================================================================
  !

  !>Sets/changes the order for a dynamic solver.
  SUBROUTINE SOLVER_DYNAMIC_ORDER_SET(SOLVER,ORDER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the dynamic solver to set the theta value for
    INTEGER(INTG), INTENT(IN) :: ORDER !<The order of the dynamic solver \see SOLVER_ROUTINES_DynamicOrderTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_DYNAMIC_ORDER_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("The solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
          DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            IF(ORDER==SOLVER_DYNAMIC_SECOND_ORDER.AND.DYNAMIC_SOLVER%DEGREE==SOLVER_DYNAMIC_FIRST_DEGREE) THEN
              LOCAL_ERROR="Invalid dynamic solver degree. You must have at least a second degree polynomial "// &
                & "interpolation for a second order dynamic solver."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            ELSE
              SELECT CASE(ORDER)
              CASE(SOLVER_DYNAMIC_FIRST_ORDER)
                DYNAMIC_SOLVER%ORDER=SOLVER_DYNAMIC_FIRST_ORDER
              CASE(SOLVER_DYNAMIC_SECOND_ORDER)
                DYNAMIC_SOLVER%ORDER=SOLVER_DYNAMIC_SECOND_ORDER
              CASE DEFAULT
                LOCAL_ERROR="The specified order of "//TRIM(NUMBER_TO_VSTRING(ORDER,"*",ERR,ERROR))//" is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            ENDIF
          ELSE
            CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DYNAMIC_ORDER_SET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_ORDER_SET",ERR,ERROR)
    CALL EXITS("SOLVER_DYNAMIC_ORDER_SET")
    RETURN 1
  END SUBROUTINE SOLVER_DYNAMIC_ORDER_SET

  !
  !================================================================================================================================
  !

  !>Sets/changes the scheme for a dynamic solver. \see OPENCMISS::CMISSSolverDynamicSchemeSet
  SUBROUTINE SOLVER_DYNAMIC_SCHEME_SET(SOLVER,SCHEME,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the dynamic solver to set the scheme for
    INTEGER(INTG), INTENT(IN) :: SCHEME !<The scheme used for a dynamic solver \see SOLVER_ROUTINES_DynamicSchemeTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    REAL(DP) :: ALPHA,BETA,GAMMA,THETA
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_DYNAMIC_SCHEME_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("The solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
          DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            SELECT CASE(SCHEME)
            CASE(SOLVER_DYNAMIC_EULER_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_EULER_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_FIRST_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,0.0_DP,ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_BACKWARD_EULER_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_BACKWARD_EULER_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_FIRST_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,1.0_DP,ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_CRANK_NICHOLSON_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_CRANK_NICHOLSON_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_FIRST_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,1.0_DP/2.0_DP,ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_GALERKIN_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_GALERKIN_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_FIRST_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,2.0_DP/3.0_DP,ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_ZLAMAL_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_ZLAMAL_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_SECOND_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/5.0_DP/6.0_DP,2.0_DP/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_SECOND_DEGREE_GEAR_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_SECOND_DEGREE_GEAR_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_SECOND_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/3.0_DP/2.0_DP,2.0_DP/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_SECOND_DEGREE_LINIGER1_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_SECOND_DEGREE_LINIGER1_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_SECOND_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/1.0848_DP,1.0_DP/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_SECOND_DEGREE_LINIGER2_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_SECOND_DEGREE_LINIGER2_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_SECOND_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/1.2184_DP,1.292_DP/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_NEWMARK1_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_NEWMARK1_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_SECOND_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_SECOND_ORDER,ERR,ERROR,*999)
              BETA=0.5_DP
              GAMMA=2.0_DP
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/GAMMA,2.0_DP*BETA/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_NEWMARK2_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_NEWMARK2_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_SECOND_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_SECOND_ORDER,ERR,ERROR,*999)
              BETA=0.3025_DP
              GAMMA=0.6_DP
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/GAMMA,2.0_DP*BETA/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_NEWMARK3_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_NEWMARK3_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_SECOND_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_SECOND_ORDER,ERR,ERROR,*999)
              BETA=0.25_DP
              GAMMA=0.5_DP
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/GAMMA,2.0_DP*BETA/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_THIRD_DEGREE_GEAR_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_THIRD_DEGREE_GEAR_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_THIRD_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/2.0_DP,11.0_DP/3.0_DP,6.0_DP/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_THIRD_DEGREE_LINIGER1_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_THIRD_DEGREE_LINIGER1_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_THIRD_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/1.84_DP,3.07_DP,4.5_DP/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_THIRD_DEGREE_LINIGER2_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_THIRD_DEGREE_LINIGER2_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_THIRD_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_FIRST_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/0.80_DP,1.03_DP,1.29_DP/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_HOUBOLT_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_HOUBOLT_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_THIRD_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_SECOND_ORDER,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/2.0_DP,11.0_DP/3.0_DP,6.0_DP/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_WILSON_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_WILSON_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_THIRD_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_SECOND_ORDER,ERR,ERROR,*999)
              THETA=1.4_DP
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/THETA,THETA**2,THETA**3/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_BOSSAK_NEWMARK1_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_BOSSAK_NEWMARK1_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_THIRD_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_SECOND_ORDER,ERR,ERROR,*999)
              ALPHA=-0.1_DP
              BETA=0.3025_DP
              GAMMA=0.5_DP-ALPHA
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/1.0_DP-ALPHA,2.0_DP/3.0_DP-ALPHA+2.0_DP*BETA,6.0_DP*BETA/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_BOSSAK_NEWMARK2_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_BOSSAK_NEWMARK2_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_THIRD_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_SECOND_ORDER,ERR,ERROR,*999)
              ALPHA=-0.1_DP
              BETA=1.0_DP/6.0_DP-1.0_DP/2.0_DP*ALPHA
              GAMMA=1.0_DP/2.0_DP-ALPHA
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/1.0_DP-ALPHA,1.0_DP-2.0_DP*ALPHA,1.0_DP-3.0_DP*ALPHA/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_HILBERT_HUGHES_TAYLOR1_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_HILBERT_HUGHES_TAYLOR1_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_THIRD_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_SECOND_ORDER,ERR,ERROR,*999)
              ALPHA=-0.1_DP
              BETA=0.3025_DP
              GAMMA=0.5_DP-ALPHA
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/1.0_DP,2.0_DP/3.0_DP+2.0_DP*BETA-2.0_DP*ALPHA**2, &
                & 6.0_DP*BETA*(1.0_DP+ALPHA)/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_HILBERT_HUGHES_TAYLOR2_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_HILBERT_HUGHES_TAYLOR2_SCHEME
              CALL SOLVER_DYNAMIC_DEGREE_SET(SOLVER,SOLVER_DYNAMIC_THIRD_DEGREE,ERR,ERROR,*999)
              CALL SOLVER_DYNAMIC_ORDER_SET(SOLVER,SOLVER_DYNAMIC_SECOND_ORDER,ERR,ERROR,*999)
              ALPHA=-0.3_DP
              BETA=0.3025_DP
              GAMMA=0.5_DP-ALPHA
              CALL SOLVER_DYNAMIC_THETA_SET(SOLVER,(/1.0_DP,2.0_DP/3.0_DP+2.0_DP*BETA-2.0_DP*ALPHA**2, &
                & 6.0_DP*BETA*(1.0_DP+ALPHA)/),ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_USER_DEFINED_SCHEME)
              DYNAMIC_SOLVER%SCHEME=SOLVER_DYNAMIC_USER_DEFINED_SCHEME
            CASE DEFAULT
              LOCAL_ERROR="The specified scheme of "//TRIM(NUMBER_TO_VSTRING(SCHEME,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          ELSE
            CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DYNAMIC_SCHEME_SET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_SCHEME_SET",ERR,ERROR)
    CALL EXITS("SOLVER_DYNAMIC_SCHEME_SET")
    RETURN 1
  END SUBROUTINE SOLVER_DYNAMIC_SCHEME_SET

  !
  !================================================================================================================================
  ! 

  !>Solve a dynamic solver 
  SUBROUTINE SOLVER_DYNAMIC_SOLVE(DYNAMIC_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER !<A pointer to the dynamic solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(SOLVER_TYPE), POINTER :: LINEAR_SOLVER,SOLVER,NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_DYNAMIC_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
      SELECT CASE(DYNAMIC_SOLVER%SOLVER_LIBRARY)
      CASE(SOLVER_CMISS_LIBRARY)
        SOLVER=>DYNAMIC_SOLVER%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN          
         ! Solve the linear dynamic problem
         IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_LINEAR) THEN
          LINEAR_SOLVER=>DYNAMIC_SOLVER%LINEAR_SOLVER
          IF(ASSOCIATED(LINEAR_SOLVER)) THEN
            !If we need to initialise the solver
            IF(.NOT.DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
              IF((DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_FIRST_ORDER.AND.DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_FIRST_DEGREE).OR. &
                & (DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_SECOND_ORDER.AND.DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_SECOND_DEGREE)) THEN
                !Assemble the solver equations
                CALL SOLVER_DYNAMIC_MEAN_PREDICTED_CALCULATE(SOLVER,ERR,ERROR,*999)
                CALL SOLVER_MATRICES_DYNAMIC_ASSEMBLE(SOLVER,SOLVER_MATRICES_LINEAR_ONLY,ERR,ERROR,*999)              
                !Solve the linear system
                CALL SOLVER_SOLVE(LINEAR_SOLVER,ERR,ERROR,*999)
                !Update dependent field with solution
                CALL SOLVER_VARIABLES_DYNAMIC_FIELD_UPDATE(SOLVER,ERR,ERROR,*999)
              ENDIF
              !Set initialised flag
              DYNAMIC_SOLVER%SOLVER_INITIALISED=.TRUE.
            ENDIF
            !Assemble the solver equations
            CALL SOLVER_DYNAMIC_MEAN_PREDICTED_CALCULATE(SOLVER,ERR,ERROR,*999)
            CALL SOLVER_MATRICES_DYNAMIC_ASSEMBLE(SOLVER,SOLVER_MATRICES_LINEAR_ONLY,ERR,ERROR,*999)
            !Solve the linear system
            CALL SOLVER_SOLVE(LINEAR_SOLVER,ERR,ERROR,*999)
          ELSE
            CALL FLAG_ERROR("Dynamic solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
         ! Solve the nonlinear dynamic problem
         ELSE IF(DYNAMIC_SOLVER%LINEARITY==SOLVER_DYNAMIC_NONLINEAR) THEN
            NONLINEAR_SOLVER=>DYNAMIC_SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            !If we need to initialise the solver
            IF(.NOT.DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
              IF(DYNAMIC_SOLVER%DEGREE/=DYNAMIC_SOLVER%ORDER) THEN
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              END IF
              DYNAMIC_SOLVER%SOLVER_INITIALISED=.TRUE.
            ENDIF
            !Assemble the solver equations
            CALL SOLVER_DYNAMIC_MEAN_PREDICTED_CALCULATE(SOLVER,ERR,ERROR,*999)
            !Solve the nonlinear system
            CALL SOLVER_SOLVE(NONLINEAR_SOLVER,ERR,ERROR,*999)
          ELSE
            CALL FLAG_ERROR("Dynamic solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
         ELSE
          CALL FLAG_ERROR("Dynamic solver linearity is not associated.",ERR,ERROR,*999)
         END IF
         !Update dependent field with solution
         CALL SOLVER_VARIABLES_DYNAMIC_FIELD_UPDATE(SOLVER,ERR,ERROR,*999)            
        ELSE
          CALL FLAG_ERROR("Dynamic solver solver is not associated.",ERR,ERROR,*999)
        ENDIF          
      CASE(SOLVER_PETSC_LIBRARY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The solver library type of "// &
          & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_DYNAMIC_SOLVE")

    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_DYNAMIC_SOLVE")
    RETURN 1
    
  END SUBROUTINE SOLVER_DYNAMIC_SOLVE
        
  !
  !================================================================================================================================
  !

  !>Sets/changes a single theta value for a dynamic solver. \see OPENCMISS::CMISSSolverDynamicThetaSet
  SUBROUTINE SOLVER_DYNAMIC_THETA_SET_DP1(SOLVER,THETA,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the dynamic solver to set the theta value for
    REAL(DP), INTENT(IN) :: THETA !<The theta value to set for the first degree polynomial
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
   
    CALL ENTERS("SOLVER_DYNAMIC_THETA_SET_DP1",ERR,ERROR,*999)

    CALL SOLVER_DYNAMIC_THETA_SET_DP(SOLVER,(/THETA/),ERR,ERROR,*999)
    
    CALL EXITS("SOLVER_DYNAMIC_THETA_SET_DP1")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_THETA_SET_DP1",ERR,ERROR)
    CALL EXITS("SOLVER_DYNAMIC_THETA_SET_DP1")
    RETURN 1
  END SUBROUTINE SOLVER_DYNAMIC_THETA_SET_DP1

  !
  !================================================================================================================================
  !

  !>Sets/changes the theta value for a dynamic solver. \see OPENCMISS::CMISSSolverDynamicThetaSet
  SUBROUTINE SOLVER_DYNAMIC_THETA_SET_DP(SOLVER,THETA,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the dynamic solver to set the theta value for
    REAL(DP), INTENT(IN) :: THETA(:) !<THEATA(degree_idx). The theta value to set for the degree_idx-1'th polynomial
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: degree_idx
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_DYNAMIC_THETA_SET_DP",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("The solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
          DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            IF(SIZE(THETA,1)>=DYNAMIC_SOLVER%DEGREE) THEN
              DO degree_idx=1,DYNAMIC_SOLVER%DEGREE
                IF(THETA(degree_idx)>=0.0_DP) THEN
                  DYNAMIC_SOLVER%THETA(degree_idx)=THETA(degree_idx)
                ELSE
                  LOCAL_ERROR="The specified theta "//TRIM(NUMBER_TO_VSTRING(degree_idx,"*",ERR,ERROR))// &
                    & " value of "//TRIM(NUMBER_TO_VSTRING(THETA(degree_idx),"*",ERR,ERROR))// &
                    & " is invalid. The theta value must be >= 0.0."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ENDDO !degree_idx
            ELSE
              LOCAL_ERROR="Invalid number of the thetas. The supplied number of thetas ("// &
                & TRIM(NUMBER_TO_VSTRING(SIZE(THETA,1),"*",ERR,ERROR))//") must be equal to the interpolation degree ("// &
                & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))//")."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DYNAMIC_THETA_SET_DP")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_THETA_SET_DP",ERR,ERROR)
    CALL EXITS("SOLVER_DYNAMIC_THETA_SET_DP")
    RETURN 1
  END SUBROUTINE SOLVER_DYNAMIC_THETA_SET_DP

  !
  !================================================================================================================================
  !

  !>Sets/changes the ALE flag for a dynamic solver.
  SUBROUTINE SOLVER_DYNAMIC_ALE_SET(SOLVER,ALE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the dynamic solver to set the theta value for
    LOGICAL :: ALE !<The ALE flag for a dynamic solver
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
!     INTEGER(INTG) :: degree_idx
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
!     TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_DYNAMIC_ALE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("The solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
          DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            DYNAMIC_SOLVER%ALE=ALE
          ELSE
            CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DYNAMIC_ALE_SET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_ALE_SET",ERR,ERROR)
    CALL EXITS("SOLVER_DYNAMIC_ALE_SET")
    RETURN 1
  END SUBROUTINE SOLVER_DYNAMIC_ALE_SET

  !
  !================================================================================================================================
  !

  !>Sets/changes the bc flag for a dynamic solver.
  SUBROUTINE SOLVER_DYNAMIC_UPDATE_BC_SET(SOLVER,UPDATE_BC,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the dynamic solver to set the theta value for
    LOGICAL :: UPDATE_BC!<The UPDATE_BC flag for a dynamic solver
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
!     INTEGER(INTG) :: degree_idx
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
!     TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_DYNAMIC_UPDATE_BC_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("The solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
          DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            DYNAMIC_SOLVER%UPDATE_BC=UPDATE_BC
          ELSE
            CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_DYNAMIC_UPDATE_BC_SET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_UPDATE_BC_SET",ERR,ERROR)
    CALL EXITS("SOLVER_DYNAMIC_UPDATE_BC_SET")
    RETURN 1
  END SUBROUTINE SOLVER_DYNAMIC_UPDATE_BC_SET

  !
  !================================================================================================================================
  !

  !>Sets/changes the dynamic times for a dynamic solver. \see OPENCMISS::CMISSSolverDynamicTimesSet
  SUBROUTINE SOLVER_DYNAMIC_TIMES_SET(SOLVER,CURRENT_TIME,TIME_INCREMENT,ERR,ERROR,*)

   !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the dynamic solver to set the times for
    REAL(DP), INTENT(IN) :: CURRENT_TIME !<The current time to set
    REAL(DP), INTENT(IN) :: TIME_INCREMENT !<The time increment to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_DYNAMIC_TIMES_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      !Note: do not check for finished here as we may wish to modify this for multiple solves.
      IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
        DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
        IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
          IF(ABS(TIME_INCREMENT)<=ZERO_TOLERANCE) THEN
            LOCAL_ERROR="The specified time increment of "//TRIM(NUMBER_TO_VSTRING(TIME_INCREMENT,"*",ERR,ERROR))// &
              & " is invalid. The time increment must not be zero."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          ELSE
            DYNAMIC_SOLVER%CURRENT_TIME=CURRENT_TIME
            DYNAMIC_SOLVER%TIME_INCREMENT=TIME_INCREMENT
          ENDIF
        ELSE
          CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
     
    CALL EXITS("SOLVER_DYNAMIC_TIMES_SET")
    RETURN
999 CALL ERRORS("SOLVER_DYNAMIC_TIMES_SET",ERR,ERROR)
    CALL EXITS("SOLVER_DYNAMIC_TIMES_SET")
    RETURN 1
  END SUBROUTINE SOLVER_DYNAMIC_TIMES_SET

  !
  !================================================================================================================================
  !

  !>Finishes the process of creating a eigenproblem solver 
  SUBROUTINE SOLVER_EIGENPROBLEM_CREATE_FINISH(EIGENPROBLEM_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(EIGENPROBLEM_SOLVER_TYPE), POINTER :: EIGENPROBLEM_SOLVER !<A pointer to the eigenproblem solver to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_EIGENPROBLEM_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(EIGENPROBLEM_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Eigenproblem solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_EIGENPROBLEM_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_EIGENPROBLEM_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_EIGENPROBLEM_CREATE_FINISH")
    RETURN 1
   
  END SUBROUTINE SOLVER_EIGENPROBLEM_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Finalise a eigenproblem solver for a solver.
  SUBROUTINE SOLVER_EIGENPROBLEM_FINALISE(EIGENPROBLEM_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(EIGENPROBLEM_SOLVER_TYPE), POINTER :: EIGENPROBLEM_SOLVER !<A pointer the eigenproblem solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_EIGENPROBLEM_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(EIGENPROBLEM_SOLVER)) THEN        
      DEALLOCATE(EIGENPROBLEM_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_EIGENPROBLEM_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_EIGENPROBLEM_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_EIGENPROBLEM_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_EIGENPROBLEM_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a eigenproblem solver for a solver.
  SUBROUTINE SOLVER_EIGENPROBLEM_INITIALISE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to initialise the eigenproblem solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    CALL ENTERS("SOLVER_EIGENPROBLEM_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(ASSOCIATED(SOLVER%EIGENPROBLEM_SOLVER)) THEN
        CALL FLAG_ERROR("Eigenproblem solver is already associated for this solver.",ERR,ERROR,*998)
      ELSE
        ALLOCATE(SOLVER%EIGENPROBLEM_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver eigenproblem solver.",ERR,ERROR,*999)
        SOLVER%EIGENPROBLEM_SOLVER%SOLVER=>SOLVER
        SOLVER%EIGENPROBLEM_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
        SOLVER%EIGENPROBLEM_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_EIGENPROBLEM_INITIALISE")
    RETURN
999 CALL SOLVER_EIGENPROBLEM_FINALISE(SOLVER%EIGENPROBLEM_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_EIGENPROBLEM_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_EIGENPROBLEM_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_EIGENPROBLEM_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for an eigenproblem solver.
  SUBROUTINE SOLVER_EIGENPROBLEM_LIBRARY_TYPE_GET(EIGENPROBLEM_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(EIGENPROBLEM_SOLVER_TYPE), POINTER :: EIGENPROBLEM_SOLVER !<A pointer the eigenproblem solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On exit, the type of library used for the eigenproblem solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
 
    CALL ENTERS("SOLVER_EIGENPROBLEM_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(EIGENPROBLEM_SOLVER)) THEN
      SOLVER_LIBRARY_TYPE=EIGENPROBLEM_SOLVER%SOLVER_LIBRARY
    ELSE
      CALL FLAG_ERROR("Eigenproblem solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_EIGENPROBLEM_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_EIGENPROBLEM_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_EIGENPROBLEM_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_EIGENPROBLEM_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library to use for an eigenproblem solver.
  SUBROUTINE SOLVER_EIGENPROBLEM_LIBRARY_TYPE_SET(EIGENPROBLEM_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(EIGENPROBLEM_SOLVER_TYPE), POINTER :: EIGENPROBLEM_SOLVER !<A pointer the eigenproblem solver to get the library type for.
    INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library for the eigenproblem solver to set. \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_EIGENPROBLEM_LIBRARY_TYPE_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(EIGENPROBLEM_SOLVER)) THEN
      SELECT CASE(SOLVER_LIBRARY_TYPE)
      CASE(SOLVER_CMISS_LIBRARY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The specified solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
          & " is invalid for an eigenproblem solver."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Dynamic solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_EIGENPROBLEM_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_EIGENPROBLEM_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_EIGENPROBLEM_LIBRARY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_EIGENPROBLEM_LIBRARY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for an eigenproblem solver matrices.
  SUBROUTINE SOLVER_EIGENPROBLEM_MATRICES_LIBRARY_TYPE_GET(EIGENPROBLEM_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(EIGENPROBLEM_SOLVER_TYPE), POINTER :: EIGENPROBLEM_SOLVER !<A pointer the eigenproblem solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: MATRICES_LIBRARY_TYPE !<On exit, the type of library used for the eigenproblem solver matrices \see DISTRIBUTED_MATRIX_VECTOR_LibraryTypes,DISTRIBUTED_MATRIX_VECTOR
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
 
    CALL ENTERS("SOLVER_EIGENPROBLEM_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(EIGENPROBLEM_SOLVER)) THEN
      MATRICES_LIBRARY_TYPE=EIGENPROBLEM_SOLVER%SOLVER_MATRICES_LIBRARY
    ELSE
      CALL FLAG_ERROR("Eigenproblem solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_EIGENPROBLEM_MATRICES_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_EIGENPROBLEM_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_EIGENPROBLEM_MATRICES_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_EIGENPROBLEM_MATRICES_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Solve a eigenproblem solver
  SUBROUTINE SOLVER_EIGENPROBLEM_SOLVE(EIGENPROBLEM_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(EIGENPROBLEM_SOLVER_TYPE), POINTER :: EIGENPROBLEM_SOLVER !<A pointer the eigenproblem solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_EIGENPROBLEM_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(EIGENPROBLEM_SOLVER)) THEN        
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Eigenproblem solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_EIGENPROBLEM_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_EIGENPROBLEM_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_EIGENPROBLEM_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_EIGENPROBLEM_SOLVE

  !
  !================================================================================================================================
  !

  !>Finishes the process of creating solver equations
  SUBROUTINE SOLVER_EQUATIONS_CREATE_FINISH(SOLVER_EQUATIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS !<A pointer the solver equations to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR

    CALL ENTERS("SOLVER_EQUATIONS_CREATE_FINISH",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
      IF(SOLVER_EQUATIONS%SOLVER_EQUATIONS_FINISHED) THEN
        CALL FLAG_ERROR("Solver equations has already been finished.",ERR,ERROR,*998)
      ELSE
        SOLVER=>SOLVER_EQUATIONS%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
          IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
            CALL FLAG_ERROR("Can not finish solver equations creation for a solver that has been linked.",ERR,ERROR,*999)
          ELSE
            !Finish of the solver mapping
            CALL SOLVER_MAPPING_CREATE_FINISH(SOLVER_EQUATIONS%SOLVER_MAPPING,ERR,ERROR,*999)
            !Now finish off with the solver specific actions
            SELECT CASE(SOLVER%SOLVE_TYPE)
            CASE(SOLVER_LINEAR_TYPE)
              CALL SOLVER_LINEAR_CREATE_FINISH(SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_NONLINEAR_TYPE)
              CALL SOLVER_NONLINEAR_CREATE_FINISH(SOLVER%NONLINEAR_SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_TYPE)
              CALL SOLVER_DYNAMIC_CREATE_FINISH(SOLVER%DYNAMIC_SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_DAE_TYPE)
              CALL SOLVER_DAE_CREATE_FINISH(SOLVER%DAE_SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_EIGENPROBLEM_TYPE)
              CALL SOLVER_EIGENPROBLEM_CREATE_FINISH(SOLVER%EIGENPROBLEM_SOLVER,ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The solver type of "//TRIM(NUMBER_TO_VSTRING(SOLVER%SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
            SOLVER_EQUATIONS%SOLVER_EQUATIONS_FINISHED=.TRUE.
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver equations is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_EQUATIONS_CREATE_FINISH")
    RETURN
999 CALL SOLVER_EQUATIONS_FINALISE(SOLVER_EQUATIONS,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_EQUATIONS_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_EQUATIONS_CREATE_FINISH")
    RETURN 1
   
  END SUBROUTINE SOLVER_EQUATIONS_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Starts the process of creating solver equations
  SUBROUTINE SOLVER_EQUATIONS_CREATE_START(SOLVER,SOLVER_EQUATIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to start the creation of solver equations on
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS !<On return, A pointer the solver equations. Must not be associated on entry
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_EQUATIONS_CREATE_START",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
          CALL FLAG_ERROR("Can not start solver equations creation for a solver that has been linked.",ERR,ERROR,*999)
        ELSE
          IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
            CALL FLAG_ERROR("Solver equations is already associated.",ERR,ERROR,*999)
          ELSE
            NULLIFY(SOLVER_EQUATIONS)
            CALL SOLVER_EQUATIONS_INITIALISE(SOLVER,ERR,ERROR,*999)
            NULLIFY(SOLVER_MAPPING)
            CALL SOLVER_MAPPING_CREATE_START(SOLVER%SOLVER_EQUATIONS,SOLVER_MAPPING,ERR,ERROR,*999)
            SELECT CASE(SOLVER%SOLVE_TYPE)
            CASE(SOLVER_LINEAR_TYPE)
              CALL SOLVER_MAPPING_SOLVER_MATRICES_NUMBER_SET(SOLVER_MAPPING,1,ERR,ERROR,*999)
            CASE(SOLVER_NONLINEAR_TYPE)
              CALL SOLVER_MAPPING_SOLVER_MATRICES_NUMBER_SET(SOLVER_MAPPING,1,ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_TYPE)
              CALL SOLVER_MAPPING_SOLVER_MATRICES_NUMBER_SET(SOLVER_MAPPING,1,ERR,ERROR,*999)
            CASE(SOLVER_DAE_TYPE)
              CALL SOLVER_MAPPING_SOLVER_MATRICES_NUMBER_SET(SOLVER_MAPPING,0,ERR,ERROR,*999)
            CASE(SOLVER_EIGENPROBLEM_TYPE)
              CALL SOLVER_MAPPING_SOLVER_MATRICES_NUMBER_SET(SOLVER_MAPPING,2,ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The solver type of "//TRIM(NUMBER_TO_VSTRING(SOLVER%SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
            SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
          ENDIF
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_EQUATIONS_CREATE_START")
    RETURN
999 CALL ERRORS("SOLVER_EQUATIONS_CREATE_START",ERR,ERROR)    
    CALL EXITS("SOLVER_EQUATIONS_CREATE_START")
    RETURN 1
   
  END SUBROUTINE SOLVER_EQUATIONS_CREATE_START
        
  !
  !================================================================================================================================
  !

  !>Destroys the solver equations
  SUBROUTINE SOLVER_EQUATIONS_DESTROY(SOLVER_EQUATIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS !<A pointer the solver equations to destroy.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_EQUATIONS_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
      CALL SOLVER_EQUATIONS_FINALISE(SOLVER_EQUATIONS,ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Solver equations is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_EQUATIONS_DESTROY")
    RETURN
999 CALL ERRORS("SOLVER_EQUATIONS_DESTROY",ERR,ERROR)    
    CALL EXITS("SOLVER_EQUATIONS_DESTROY")
    RETURN 1
   
  END SUBROUTINE SOLVER_EQUATIONS_DESTROY
        
  !
  !================================================================================================================================
  !

  !>Adds equations sets to solver equations. \see OPENCMISS::CMISSSolverEquationsEquationsSetAdd
  SUBROUTINE SOLVER_EQUATIONS_EQUATIONS_SET_ADD(SOLVER_EQUATIONS,EQUATIONS_SET,EQUATIONS_SET_INDEX,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS !<A pointer the solver equations to add the equations set to.
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET !<A pointer to the equations set to add
    INTEGER(INTG), INTENT(OUT) :: EQUATIONS_SET_INDEX !<On exit, the index of the equations set that has been added
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_EQUATIONS_EQUATIONS_SET_ADD",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
      IF(SOLVER_EQUATIONS%SOLVER_EQUATIONS_FINISHED) THEN
        CALL FLAG_ERROR("Solver equations has already been finished.",ERR,ERROR,*999)
      ELSE
        SOLVER=>SOLVER_EQUATIONS%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
          IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
            CALL FLAG_ERROR("Can not add an equations set for a solver that has been linked.",ERR,ERROR,*999)
          ELSE
            SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
            IF(ASSOCIATED(SOLVER_MAPPING)) THEN          
              IF(ASSOCIATED(EQUATIONS_SET)) THEN
                EQUATIONS=>EQUATIONS_SET%EQUATIONS
                IF(ASSOCIATED(EQUATIONS)) THEN
                  IF(EQUATIONS%LINEARITY==SOLVER_EQUATIONS%LINEARITY) THEN
                    IF(EQUATIONS%TIME_DEPENDENCE==SOLVER_EQUATIONS%TIME_DEPENDENCE) THEN
                      CALL SOLVER_MAPPING_EQUATIONS_SET_ADD(SOLVER_MAPPING,EQUATIONS_SET,EQUATIONS_SET_INDEX,ERR,ERROR,*999)
                    ELSE
                      LOCAL_ERROR="Invalid equations set up. The time dependence of the equations set to add ("// &
                        & TRIM(NUMBER_TO_VSTRING(EQUATIONS%TIME_DEPENDENCE,"*",ERR,ERROR))// &
                        & ") does not match the solver equations time dependence ("// &
                        & TRIM(NUMBER_TO_VSTRING(SOLVER_EQUATIONS%TIME_DEPENDENCE,"*",ERR,ERROR))//")."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    LOCAL_ERROR="Invalid equations set up. The linearity of the equations set to add ("// &
                      & TRIM(NUMBER_TO_VSTRING(EQUATIONS%LINEARITY,"*",ERR,ERROR))// &
                      & ") does not match the solver equations linearity ("// &
                      & TRIM(NUMBER_TO_VSTRING(SOLVER_EQUATIONS%LINEARITY,"*",ERR,ERROR))//")."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)            
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("Equations set equations is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver equations solver mapping is not associated.",ERR,ERROR,*999)
            ENDIF
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver equations is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_EQUATIONS_EQUATIONS_SET_ADD")
    RETURN
999 CALL ERRORS("SOLVER_EQUATIONS_EQUATIONS_SET_ADD",ERR,ERROR)    
    CALL EXITS("SOLVER_EQUATIONS_EQUATIONS_SET_ADD")
    RETURN 1
   
  END SUBROUTINE SOLVER_EQUATIONS_EQUATIONS_SET_ADD
        
  !
  !================================================================================================================================
  !

  !>Finalises the solver equations and deallocates all memory.
  SUBROUTINE SOLVER_EQUATIONS_FINALISE(SOLVER_EQUATIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS !<A pointer the solver equations to finalise.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_EQUATIONS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
      IF(ASSOCIATED(SOLVER_EQUATIONS%SOLVER_MAPPING)) CALL SOLVER_MAPPING_DESTROY(SOLVER_EQUATIONS%SOLVER_MAPPING,ERR,ERROR,*999)
      IF(ASSOCIATED(SOLVER_EQUATIONS%SOLVER_MATRICES)) CALL SOLVER_MATRICES_DESTROY(SOLVER_EQUATIONS%SOLVER_MATRICES,ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_EQUATIONS_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_EQUATIONS_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_EQUATIONS_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_EQUATIONS_FINALISE
        
  !
  !================================================================================================================================
  !

  !>Initialises the solver equations for a solver.
  SUBROUTINE SOLVER_EQUATIONS_INITIALISE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to initialise the solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    CALL ENTERS("SOLVER_EQUATIONS_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(ASSOCIATED(SOLVER%SOLVER_EQUATIONS)) THEN
        CALL FLAG_ERROR("Solver equations is already associated for this solver.",ERR,ERROR,*998)
      ELSE
        ALLOCATE(SOLVER%SOLVER_EQUATIONS,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver equations.",ERR,ERROR,*999)
        SOLVER%SOLVER_EQUATIONS%SOLVER=>SOLVER
        SOLVER%SOLVER_EQUATIONS%SOLVER_EQUATIONS_FINISHED=.FALSE.
        SOLVER%SOLVER_EQUATIONS%SPARSITY_TYPE=SOLVER_SPARSE_MATRICES
        NULLIFY(SOLVER%SOLVER_EQUATIONS%SOLVER_MAPPING)
        NULLIFY(SOLVER%SOLVER_EQUATIONS%SOLVER_MATRICES)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_EQUATIONS_INITIALISE")
    RETURN
999 CALL SOLVER_EQUATIONS_FINALISE(SOLVER%SOLVER_EQUATIONS,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_EQUATIONS_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_EQUATIONS_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_EQUATIONS_INITIALISE
        
  !
  !================================================================================================================================
  !

  !>Adds an interface condition to the solver equations. \see OPENCMISS::CMISSSolverEquationsInterfaceConditionAdd
  SUBROUTINE SOLVER_EQUATIONS_INTERFACE_CONDITION_ADD(SOLVER_EQUATIONS,INTERFACE_CONDITION,INTERFACE_CONDITION_INDEX,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS !<A pointer the solver equations to add the interface condition to.
    TYPE(INTERFACE_CONDITION_TYPE), POINTER :: INTERFACE_CONDITION !<A pointer to the interface condition to add
    INTEGER(INTG), INTENT(OUT) :: INTERFACE_CONDITION_INDEX !<On exit, the index of the interface condition that has been added
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(INTERFACE_EQUATIONS_TYPE), POINTER :: INTERFACE_EQUATIONS
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    
    CALL ENTERS("SOLVER_EQUATIONS_INTERFACE_CONDITION_ADD",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
      IF(SOLVER_EQUATIONS%SOLVER_EQUATIONS_FINISHED) THEN
        CALL FLAG_ERROR("Solver equations has already been finished.",ERR,ERROR,*999)
      ELSE
        SOLVER=>SOLVER_EQUATIONS%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
          IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
            CALL FLAG_ERROR("Can not add an equations set for a solver that has been linked.",ERR,ERROR,*999)
          ELSE
            SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
            IF(ASSOCIATED(SOLVER_MAPPING)) THEN          
              IF(ASSOCIATED(INTERFACE_CONDITION)) THEN
                INTERFACE_EQUATIONS=>INTERFACE_CONDITION%INTERFACE_EQUATIONS
                IF(ASSOCIATED(INTERFACE_EQUATIONS)) THEN
                  CALL SOLVER_MAPPING_INTERFACE_CONDITION_ADD(SOLVER_MAPPING,INTERFACE_CONDITION,INTERFACE_CONDITION_INDEX, &
                    & ERR,ERROR,*999)
                ELSE
                  CALL FLAG_ERROR("Interface condition interface equations is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("Interface condition is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver equations solver mapping is not associated.",ERR,ERROR,*999)
            ENDIF
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver equations is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_EQUATIONS_INTERFACE_CONDITION_ADD")
    RETURN
999 CALL ERRORS("SOLVER_EQUATIONS_INTERFACE_CONDITION_ADD",ERR,ERROR)    
    CALL EXITS("SOLVER_EQUATIONS_INTERFACE_CONDITION_ADD")
    RETURN 1
   
  END SUBROUTINE SOLVER_EQUATIONS_INTERFACE_CONDITION_ADD
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the linearity type for solver equations
  SUBROUTINE SOLVER_EQUATIONS_LINEARITY_TYPE_SET(SOLVER_EQUATIONS,LINEARITY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS !<A pointer the solver equations to set the linearity type for
    INTEGER(INTG), INTENT(IN) :: LINEARITY_TYPE !<The type of linearity to be set \see SOLVER_ROUTINES_EquationLinearityTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_EQUATIONS_LINEARITY_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
      IF(SOLVER_EQUATIONS%SOLVER_EQUATIONS_FINISHED) THEN
        CALL FLAG_ERROR("Solver equations has already been finished.",ERR,ERROR,*999)
      ELSE
        SOLVER=>SOLVER_EQUATIONS%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
          IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
            CALL FLAG_ERROR("Can not set equations linearity for a solver that has been linked.",ERR,ERROR,*999)
          ELSE
            SELECT CASE(LINEARITY_TYPE)
            CASE(SOLVER_EQUATIONS_LINEAR)
              SOLVER_EQUATIONS%LINEARITY=SOLVER_EQUATIONS_LINEAR
            CASE(SOLVER_EQUATIONS_NONLINEAR)
              SOLVER_EQUATIONS%LINEARITY=SOLVER_EQUATIONS_NONLINEAR
            CASE DEFAULT
              LOCAL_ERROR="The specified solver equations linearity type of "// &
                & TRIM(NUMBER_TO_VSTRING(LINEARITY_TYPE,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver equations is not associated.",ERR,ERROR,*999)
    ENDIF
   
    CALL EXITS("SOLVER_EQUATIONS_LINEARITY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_EQUATIONS_LINEARITY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_EQUATIONS_LINEARITY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_EQUATIONS_LINEARITY_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the sparsity type for solver equations. \see OPENCMISS::CMISSSolverEquationsSpartsityTypeSet
  SUBROUTINE SOLVER_EQUATIONS_SPARSITY_TYPE_SET(SOLVER_EQUATIONS,SPARSITY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS !<A pointer the solver equations to set the sparsity type for
    INTEGER(INTG), INTENT(IN) :: SPARSITY_TYPE !<The type of solver equations sparsity to be set \see SOLVER_ROUTINES_SparsityTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_EQUATIONS_SPARSITY_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
      IF(SOLVER_EQUATIONS%SOLVER_EQUATIONS_FINISHED) THEN
        CALL FLAG_ERROR("Solver equations has already been finished.",ERR,ERROR,*999)
      ELSE
        SOLVER=>SOLVER_EQUATIONS%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
          IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
            CALL FLAG_ERROR("Can not set equations sparsity for a solver that has been linked.",ERR,ERROR,*999)
          ELSE
!!TODO: Maybe set the sparsity in the different types of solvers. e.g., a sparse integrator doesn't mean much.
            SELECT CASE(SPARSITY_TYPE)
            CASE(SOLVER_SPARSE_MATRICES)
              SOLVER_EQUATIONS%SPARSITY_TYPE=SOLVER_SPARSE_MATRICES
            CASE(SOLVER_FULL_MATRICES)
              SOLVER_EQUATIONS%SPARSITY_TYPE=SOLVER_FULL_MATRICES
            CASE DEFAULT
              LOCAL_ERROR="The specified solver equations sparsity type of "// &
                & TRIM(NUMBER_TO_VSTRING(SPARSITY_TYPE,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver equations is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_EQUATIONS_SPARSITY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_EQUATIONS_SPARSITY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_EQUATIONS_SPARSITY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_EQUATIONS_SPARSITY_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the time dependence type for solver equations
  SUBROUTINE SOLVER_EQUATIONS_TIME_DEPENDENCE_TYPE_SET(SOLVER_EQUATIONS,TIME_DEPENDENCE_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS !<A pointer the solver equations to set the sparsity type for
    INTEGER(INTG), INTENT(IN) :: TIME_DEPENDENCE_TYPE !<The type of time dependence to be set \see SOLVER_ROUTINES_EquationTimeDependenceTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_EQUATIONS_TIME_DEPENDENCE_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
      IF(SOLVER_EQUATIONS%SOLVER_EQUATIONS_FINISHED) THEN
        CALL FLAG_ERROR("Solver equations has already been finished.",ERR,ERROR,*999)
      ELSE
        SOLVER=>SOLVER_EQUATIONS%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
          IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
            CALL FLAG_ERROR("Can not set equations time dependence for a solver that has been linked.",ERR,ERROR,*999)
          ELSE
            SELECT CASE(TIME_DEPENDENCE_TYPE)
            CASE(SOLVER_EQUATIONS_STATIC)
              SOLVER_EQUATIONS%TIME_DEPENDENCE=SOLVER_EQUATIONS_STATIC
            CASE(SOLVER_EQUATIONS_QUASISTATIC)
              SOLVER_EQUATIONS%TIME_DEPENDENCE=SOLVER_EQUATIONS_QUASISTATIC
            CASE(SOLVER_EQUATIONS_FIRST_ORDER_DYNAMIC)
              SOLVER_EQUATIONS%TIME_DEPENDENCE=SOLVER_EQUATIONS_FIRST_ORDER_DYNAMIC
            CASE(SOLVER_EQUATIONS_SECOND_ORDER_DYNAMIC)
              SOLVER_EQUATIONS%TIME_DEPENDENCE=SOLVER_EQUATIONS_SECOND_ORDER_DYNAMIC
            CASE(SOLVER_EQUATIONS_TIME_STEPPING)
              SOLVER_EQUATIONS%TIME_DEPENDENCE=SOLVER_EQUATIONS_TIME_STEPPING
            CASE DEFAULT
              LOCAL_ERROR="The specified solver equations time dependence type of "// &
                & TRIM(NUMBER_TO_VSTRING(TIME_DEPENDENCE_TYPE,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver equations solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver equations is not associated.",ERR,ERROR,*999)
    ENDIF
   
    CALL EXITS("SOLVER_EQUATIONS_TIME_DEPENDENCE_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_EQUATIONS_TIME_DEPENDENCE_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_EQUATIONS_TIME_DEPENDENCE_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_EQUATIONS_TIME_DEPENDENCE_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Finalises a solver and deallocates all memory.
  SUBROUTINE SOLVER_FINALISE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      CALL SOLVER_LINEAR_FINALISE(SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_NONLINEAR_FINALISE(SOLVER%NONLINEAR_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_DYNAMIC_FINALISE(SOLVER%DYNAMIC_SOLVER,ERR,ERROR,*999)        
      CALL SOLVER_DAE_FINALISE(SOLVER%DAE_SOLVER,ERR,ERROR,*999)        
      CALL SOLVER_EIGENPROBLEM_FINALISE(SOLVER%EIGENPROBLEM_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_OPTIMISER_FINALISE(SOLVER%OPTIMISER_SOLVER,ERR,ERROR,*999)
      IF(.NOT.ASSOCIATED(SOLVER%LINKING_SOLVER)) &
        & CALL SOLVER_EQUATIONS_FINALISE(SOLVER%SOLVER_EQUATIONS,ERR,ERROR,*999)
      DEALLOCATE(SOLVER)
    ENDIF 
        
    CALL EXITS("SOLVER_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a solver for a control loop
  SUBROUTINE SOLVER_INITIALISE(SOLVERS,SOLVER_INDEX,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVERS_TYPE), POINTER :: SOLVERS !<A pointer the solvers to initialise the solver for
    INTEGER(INTG), INTENT(IN) :: SOLVER_INDEX !<The solver index in solvers to initialise the solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR
    
    CALL ENTERS("SOLVER_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVERS)) THEN
      IF(SOLVER_INDEX>0.AND.SOLVER_INDEX<=SOLVERS%NUMBER_OF_SOLVERS) THEN
        IF(ALLOCATED(SOLVERS%SOLVERS)) THEN
          IF(ASSOCIATED(SOLVERS%SOLVERS(SOLVER_INDEX)%PTR)) THEN
            CALL FLAG_ERROR("Solver pointer is already associated for this solver index.",ERR,ERROR,*998)
          ELSE
            ALLOCATE(SOLVERS%SOLVERS(SOLVER_INDEX)%PTR,STAT=ERR)
            IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver.",ERR,ERROR,*999)
            SOLVERS%SOLVERS(SOLVER_INDEX)%PTR%SOLVERS=>SOLVERS
            CALL SOLVER_INITIALISE_PTR(SOLVERS%SOLVERS(SOLVER_INDEX)%PTR,ERR,ERROR,*999)
            SOLVERS%SOLVERS(SOLVER_INDEX)%PTR%GLOBAL_NUMBER=SOLVER_INDEX
            !Default to a linear solver and initialise
            SOLVERS%SOLVERS(SOLVER_INDEX)%PTR%SOLVE_TYPE=SOLVER_LINEAR_TYPE
            CALL SOLVER_LINEAR_INITIALISE(SOLVERS%SOLVERS(SOLVER_INDEX)%PTR,ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solvers solvers is not allocated.",ERR,ERROR,*998)
        ENDIF
      ELSE
        LOCAL_ERROR="The solver index of "//TRIM(NUMBER_TO_VSTRING(SOLVER_INDEX,"*",ERR,ERROR))// &
          & " is invalid. The solver index must be > 0 and <= "// &
          & TRIM(NUMBER_TO_VSTRING(SOLVERS%NUMBER_OF_SOLVERS,"*",ERR,ERROR))//"."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*998)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solvers is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_INITIALISE")
    RETURN
999 CALL SOLVER_FINALISE(SOLVERS%SOLVERS(SOLVER_INDEX)%PTR,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_INITIALISE

  !
  !================================================================================================================================
  !

  !>Initialise a solver 
  SUBROUTINE SOLVER_INITIALISE_PTR(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to initialise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    
    CALL ENTERS("SOLVER_INITIALISE_PTR",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      NULLIFY(SOLVER%LINKING_SOLVER)
      NULLIFY(SOLVER%LINKED_SOLVER)
      SOLVER%SOLVER_FINISHED=.FALSE.
      SOLVER%OUTPUT_TYPE=SOLVER_NO_OUTPUT
      NULLIFY(SOLVER%LINEAR_SOLVER)
      NULLIFY(SOLVER%NONLINEAR_SOLVER)
      NULLIFY(SOLVER%DYNAMIC_SOLVER)
      NULLIFY(SOLVER%DAE_SOLVER)
      NULLIFY(SOLVER%EIGENPROBLEM_SOLVER)
      NULLIFY(SOLVER%OPTIMISER_SOLVER)
      NULLIFY(SOLVER%SOLVER_EQUATIONS)
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_INITIALISE_PTR")
    RETURN
999 CALL ERRORS("SOLVER_INITIALISE_PTR",ERR,ERROR)    
    CALL EXITS("SOLVER_INITIALISE_PTR")
    RETURN 1
    
  END SUBROUTINE SOLVER_INITIALISE_PTR

  !
  !================================================================================================================================
  !

  !>Gets the type of library to use for the solver \see OPENCMISS::CMISSSolverLibraryTypeGet
  SUBROUTINE SOLVER_LIBRARY_TYPE_GET(SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to get the library type of
    INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On exit, the type of library used for the solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(EIGENPROBLEM_SOLVER_TYPE), POINTER :: EIGENPROBLEM_SOLVER
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(OPTIMISER_SOLVER_TYPE), POINTER :: OPTIMISER_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      SELECT CASE(SOLVER%SOLVE_TYPE)
      CASE(SOLVER_LINEAR_TYPE)
        LINEAR_SOLVER=>SOLVER%LINEAR_SOLVER
        IF(ASSOCIATED(LINEAR_SOLVER)) THEN
          CALL SOLVER_LINEAR_LIBRARY_TYPE_GET(LINEAR_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Solver linear solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_NONLINEAR_TYPE)
        NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
        IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
          CALL SOLVER_NONLINEAR_LIBRARY_TYPE_GET(NONLINEAR_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Solver nonlinear solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DYNAMIC_TYPE)
        DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
        IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN         
          CALL SOLVER_DYNAMIC_LIBRARY_TYPE_GET(DYNAMIC_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
          SOLVER_LIBRARY_TYPE=DYNAMIC_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("Solver dynamic solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DAE_TYPE)
        DAE_SOLVER=>SOLVER%DAE_SOLVER
        IF(ASSOCIATED(DAE_SOLVER)) THEN
          CALL SOLVER_DAE_LIBRARY_TYPE_GET(DAE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Solver differential-algebraic solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_EIGENPROBLEM_TYPE)
        EIGENPROBLEM_SOLVER=>SOLVER%EIGENPROBLEM_SOLVER
        IF(ASSOCIATED(EIGENPROBLEM_SOLVER)) THEN
          CALL SOLVER_EIGENPROBLEM_LIBRARY_TYPE_GET(EIGENPROBLEM_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Solver eigenproblem solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_OPTIMISER_TYPE)
        OPTIMISER_SOLVER=>SOLVER%OPTIMISER_SOLVER
        IF(ASSOCIATED(OPTIMISER_SOLVER)) THEN
          CALL SOLVER_OPTIMISER_LIBRARY_TYPE_GET(OPTIMISER_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Solver optimiser solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The solver type of "//TRIM(NUMBER_TO_VSTRING(SOLVER%SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LIBRARY_TYPE_GET
  
  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library type to use for the solver. \see OPENCMISS::CMISSSolverLibraryTypeSet
  SUBROUTINE SOLVER_LIBRARY_TYPE_SET(SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the type of
    INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library to use for the solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(EIGENPROBLEM_SOLVER_TYPE), POINTER :: EIGENPROBLEM_SOLVER
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(OPTIMISER_SOLVER_TYPE), POINTER :: OPTIMISER_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LIBRARY_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has alredy been finished.",ERR,ERROR,*999)
      ELSE
        SELECT CASE(SOLVER%SOLVE_TYPE)
        CASE(SOLVER_LINEAR_TYPE)
          LINEAR_SOLVER=>SOLVER%LINEAR_SOLVER
          IF(ASSOCIATED(LINEAR_SOLVER)) THEN
            CALL SOLVER_LINEAR_LIBRARY_TYPE_SET(LINEAR_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
          ELSE
            CALL FLAG_ERROR("Solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        CASE(SOLVER_NONLINEAR_TYPE)
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            CALL SOLVER_NONLINEAR_LIBRARY_TYPE_SET(NONLINEAR_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
          ELSE
            CALL FLAG_ERROR("Solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        CASE(SOLVER_DYNAMIC_TYPE)
          DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            CALL SOLVER_DYNAMIC_LIBRARY_TYPE_SET(DYNAMIC_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
          ELSE
            CALL FLAG_ERROR("Solver dynamic solver is not associated.",ERR,ERROR,*999)
          ENDIF
        CASE(SOLVER_DAE_TYPE)
          DAE_SOLVER=>SOLVER%DAE_SOLVER
          IF(ASSOCIATED(DAE_SOLVER)) THEN
            CALL SOLVER_DAE_LIBRARY_TYPE_SET(DAE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
          ELSE
            CALL FLAG_ERROR("Solver differential-algebraic equation solver is not associated.",ERR,ERROR,*999)
          ENDIF
        CASE(SOLVER_EIGENPROBLEM_TYPE)
          EIGENPROBLEM_SOLVER=>SOLVER%EIGENPROBLEM_SOLVER
          IF(ASSOCIATED(EIGENPROBLEM_SOLVER)) THEN
            CALL SOLVER_EIGENPROBLEM_LIBRARY_TYPE_SET(EIGENPROBLEM_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
            SELECT CASE(SOLVER_LIBRARY_TYPE)
            CASE(SOLVER_CMISS_LIBRARY)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE(SOLVER_PETSC_LIBRARY)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          ELSE
            CALL FLAG_ERROR("Solver eigenproblem solver is not associated.",ERR,ERROR,*999)
          ENDIF
        CASE(SOLVER_OPTIMISER_TYPE)
          OPTIMISER_SOLVER=>SOLVER%OPTIMISER_SOLVER
          IF(ASSOCIATED(OPTIMISER_SOLVER)) THEN
            CALL SOLVER_OPTIMISER_LIBRARY_TYPE_SET(OPTIMISER_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
          ELSE
            CALL FLAG_ERROR("Solver optimiser solver is not associated.",ERR,ERROR,*999)
          ENDIF
        CASE DEFAULT
          LOCAL_ERROR="The solver type of "//TRIM(NUMBER_TO_VSTRING(SOLVER%SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LIBRARY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LIBRARY_TYPE_SET
  
  !
  !================================================================================================================================
  !

  !>Finishes the process of creating a linear solver 
  SUBROUTINE SOLVER_LINEAR_CREATE_FINISH(LINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER !<A pointer to the linear solver to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER
    TYPE(NEWTON_TRUSTREGION_SOLVER_TYPE), POINTER :: TRUSTREGION_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(SOLVER_TYPE), POINTER :: LINKING_SOLVER,SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LINEAR_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_SOLVER)) THEN
      SOLVER=>LINEAR_SOLVER%SOLVER
      IF(ASSOCIATED(SOLVER)) THEN
        LINKING_SOLVER=>SOLVER%LINKING_SOLVER
        IF(ASSOCIATED(LINKING_SOLVER)) THEN
          IF(LINKING_SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
            NONLINEAR_SOLVER=>LINKING_SOLVER%NONLINEAR_SOLVER
            IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
              IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
                NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
                IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                  SELECT CASE(NEWTON_SOLVER%NEWTON_SOLVE_TYPE)
                  CASE(SOLVER_NEWTON_LINESEARCH)
                    LINESEARCH_SOLVER=>NEWTON_SOLVER%LINESEARCH_SOLVER
                    IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
                      LINEAR_SOLVER%LINKED_NEWTON_PETSC_SOLVER=LINESEARCH_SOLVER%SOLVER_LIBRARY==SOLVER_PETSC_LIBRARY
                    ELSE
                      CALL FLAG_ERROR("Newton solver linesearch solver is not associated.",ERR,ERROR,*999)
                    ENDIF
                  CASE(SOLVER_NEWTON_TRUSTREGION)
                    TRUSTREGION_SOLVER=>NEWTON_SOLVER%TRUSTREGION_SOLVER
                    IF(ASSOCIATED(TRUSTREGION_SOLVER)) THEN
                      LINEAR_SOLVER%LINKED_NEWTON_PETSC_SOLVER=TRUSTREGION_SOLVER%SOLVER_LIBRARY==SOLVER_PETSC_LIBRARY
                    ELSE
                      CALL FLAG_ERROR("Newton solver linesearch solver is not associated.",ERR,ERROR,*999)
                    ENDIF
                  CASE DEFAULT
                    LOCAL_ERROR="The Newton solve type of "// &
                      & TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVER%NEWTON_SOLVE_TYPE,"*",ERR,ERROR))//"is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT
                ELSE
                  CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDIF
            ELSE
              CALL FLAG_ERROR("Linking solver nonlinear solver is not associated.",ERR,ERROR,*999)
            ENDIF
          ENDIF
        ENDIF
        SELECT CASE(LINEAR_SOLVER%LINEAR_SOLVE_TYPE)
        CASE(SOLVER_LINEAR_DIRECT_SOLVE_TYPE)
          CALL SOLVER_LINEAR_DIRECT_CREATE_FINISH(LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
        CASE(SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE)
          CALL SOLVER_LINEAR_ITERATIVE_CREATE_FINISH(LINEAR_SOLVER%ITERATIVE_SOLVER,ERR,ERROR,*999)
        CASE DEFAULT
          LOCAL_ERROR="The linear solver type of "//TRIM(NUMBER_TO_VSTRING(LINEAR_SOLVER%LINEAR_SOLVE_TYPE,"*",ERR,ERROR))// &
            & " is invalid."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
      ELSE
        CALL FLAG_ERROR("Linear solver solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_CREATE_FINISH")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Finalise a Cholesky direct linear solver and deallocate all memory.
  SUBROUTINE SOLVER_LINEAR_DIRECT_CHOLESKY_FINALISE(DIRECT_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER !<A pointer to the linear direct solver to finalise the Cholesky solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_LINEAR_DIRECT_CHOLESKY_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DIRECT_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("SOLVER_LINEAR_DIRECT_CHOLESKY_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_CHOLESKY_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_CHOLESKY_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_CHOLESKY_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a Cholesky direct linear solver for a direct linear solver.
  SUBROUTINE SOLVER_LINEAR_DIRECT_CHOLESKY_INITIALISE(DIRECT_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER !<A pointer the direct linear solver to initialise the Cholesky direct linear solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    
    CALL ENTERS("SOLVER_LINEAR_DIRECT_CHOLESKY_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DIRECT_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Direct linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_DIRECT_CHOLESKY_INITIALISE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_CHOLESKY_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_CHOLESKY_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_CHOLESKY_INITIALISE

  !
  !================================================================================================================================
  !

  !>Finishes the process of creating a linear direct solver 
  SUBROUTINE SOLVER_LINEAR_DIRECT_CREATE_FINISH(LINEAR_DIRECT_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: LINEAR_DIRECT_SOLVER !<A pointer to the linear direct solver to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER
    TYPE(DISTRIBUTED_MATRIX_TYPE), POINTER :: SOLVER_MATRIX
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LINEAR_DIRECT_CREATE_FINISH",ERR,ERROR,*999)
    
    IF(ASSOCIATED(LINEAR_DIRECT_SOLVER)) THEN
      LINEAR_SOLVER=>LINEAR_DIRECT_SOLVER%LINEAR_SOLVER
      IF(ASSOCIATED(LINEAR_SOLVER)) THEN
        SOLVER=>LINEAR_SOLVER%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
!
! TODO -> FIX THIS: PETSC only with PETSC !!! sebk
!
!           IF(.NOT.LINEAR_SOLVER%LINKED_NEWTON_PETSC_SOLVER) &
!             & CALL FLAG_ERROR("Only not use a direct solver with a linked PETSC nonlinear Newton solver.",ERR,ERROR,*999)
          SELECT CASE(LINEAR_DIRECT_SOLVER%DIRECT_SOLVER_TYPE)
          CASE(SOLVER_DIRECT_LU)
            SELECT CASE(LINEAR_DIRECT_SOLVER%SOLVER_LIBRARY)
            CASE(SOLVER_CMISS_LIBRARY)
              !?????
              IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
                SOLVER_EQUATIONS=>SOLVER%LINKING_SOLVER%SOLVER_EQUATIONS
                IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
                  SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
                  IF(.NOT.ASSOCIATED(SOLVER_MATRICES)) &
                    & CALL FLAG_ERROR("Linked solver equation solver matrices is not associated.",ERR,ERROR,*999)
                ELSE
                  CALL FLAG_ERROR("Linked solver solver equations is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
                IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
                  !Create the solver matrices
                  CALL SOLVER_MATRICES_CREATE_START(SOLVER_EQUATIONS,SOLVER_MATRICES,ERR,ERROR,*999)
                  CALL SOLVER_MATRICES_LIBRARY_TYPE_SET(SOLVER_MATRICES,SOLVER_CMISS_LIBRARY,ERR,ERROR,*999)
                  SELECT CASE(SOLVER_EQUATIONS%SPARSITY_TYPE)
                  CASE(SOLVER_SPARSE_MATRICES)
                    CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_COMPRESSED_ROW_STORAGE_TYPE/), &
                      & ERR,ERROR,*999)
                  CASE(SOLVER_FULL_MATRICES)
                    CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_BLOCK_STORAGE_TYPE/), &
                      & ERR,ERROR,*999)
                  CASE DEFAULT
                    LOCAL_ERROR="The specified solver equations sparsity type of "// &
                      & TRIM(NUMBER_TO_VSTRING(SOLVER_EQUATIONS%SPARSITY_TYPE,"*",ERR,ERROR))// &
                      & " is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT
                  CALL SOLVER_MATRICES_CREATE_FINISH(SOLVER_MATRICES,ERR,ERROR,*999)
                ELSE
                  CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDIF
            CASE(SOLVER_MUMPS_LIBRARY)
              !Call MUMPS through PETSc
              IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
                SOLVER_EQUATIONS=>SOLVER%LINKING_SOLVER%SOLVER_EQUATIONS
                IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
                  SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
                  IF(.NOT.ASSOCIATED(SOLVER_MATRICES)) &
                    & CALL FLAG_ERROR("Linked solver equation solver matrices is not associated.",ERR,ERROR,*999)
                ELSE
                  CALL FLAG_ERROR("Linked solver solver equations is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
                IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
                  !Create the solver matrices and vectors
                  NULLIFY(SOLVER_MATRICES)
                  CALL SOLVER_MATRICES_CREATE_START(SOLVER_EQUATIONS,SOLVER_MATRICES,ERR,ERROR,*999)
                  CALL SOLVER_MATRICES_LIBRARY_TYPE_SET(SOLVER_MATRICES,SOLVER_PETSC_LIBRARY,ERR,ERROR,*999)
                  SELECT CASE(SOLVER_EQUATIONS%SPARSITY_TYPE)
                  CASE(SOLVER_SPARSE_MATRICES)
                    CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_COMPRESSED_ROW_STORAGE_TYPE/), &
                      & ERR,ERROR,*999)
                  CASE(SOLVER_FULL_MATRICES)
                    CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_BLOCK_STORAGE_TYPE/), &
                      & ERR,ERROR,*999)
                  CASE DEFAULT
                    LOCAL_ERROR="The specified solver equations sparsity type of "// &
                      & TRIM(NUMBER_TO_VSTRING(SOLVER_EQUATIONS%SPARSITY_TYPE,"*",ERR,ERROR))// &
                      & " is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT
                  CALL SOLVER_MATRICES_CREATE_FINISH(SOLVER_MATRICES,ERR,ERROR,*999)
                ELSE
                  CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDIF

              CALL PETSC_KSPCREATE(COMPUTATIONAL_ENVIRONMENT%MPI_COMM,LINEAR_DIRECT_SOLVER%KSP,ERR,ERROR,*999)
              
              !Set any further KSP options from the command line options
              CALL PETSC_KSPSETFROMOPTIONS(LINEAR_DIRECT_SOLVER%KSP,ERR,ERROR,*999)
              !Set the solver matrix to be the KSP matrix
              IF(SOLVER_MATRICES%NUMBER_OF_MATRICES==1) THEN
                SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(1)%PTR%MATRIX
                IF(ASSOCIATED(SOLVER_MATRIX)) THEN
                  IF(ASSOCIATED(SOLVER_MATRIX%PETSC)) THEN
                    CALL PETSC_KSPSETOPERATORS(LINEAR_DIRECT_SOLVER%KSP,SOLVER_MATRIX%PETSC%MATRIX,SOLVER_MATRIX%PETSC%MATRIX, &
                      & PETSC_DIFFERENT_NONZERO_PATTERN,ERR,ERROR,*999)
#if ( PETSC_VERSION_MAJOR == 3 )
                    !Set the KSP type to preonly
                    CALL PETSC_KSPSETTYPE(LINEAR_DIRECT_SOLVER%KSP,PETSC_KSPPREONLY,ERR,ERROR,*999)
                    !Get the pre-conditioner
                    CALL PETSC_KSPGETPC(LINEAR_DIRECT_SOLVER%KSP,LINEAR_DIRECT_SOLVER%PC,ERR,ERROR,*999)
                    !Set the PC type to LU
                    CALL PETSC_PCSETTYPE(LINEAR_DIRECT_SOLVER%PC,PETSC_PCLU,ERR,ERROR,*999)
                    !Set the PC factorisation package to MUMPS
                    CALL PETSC_PCFACTORSETMATSOLVERPACKAGE(LINEAR_DIRECT_SOLVER%PC,PETSC_MAT_SOLVER_MUMPS,ERR,ERROR,*999)
#else                    
                    !Set the matrix type to MUMPS    
                    CALL PETSC_MATSETTYPE(SOLVER_MATRIX%PETSC%MATRIX,PETSC_AIJMUMPS,ERR,ERROR,*999)
#endif
                  ELSE
                    CALL FLAG_ERROR("Solver matrix PETSc is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("Solver matrices distributed matrix is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                LOCAL_ERROR="The given number of solver matrices of "// &
                  & TRIM(NUMBER_TO_VSTRING(SOLVER_MATRICES%NUMBER_OF_MATRICES,"*",ERR,ERROR))// &
                  & " is invalid. There should only be one solver matrix for a linear direct solver."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
            CASE(SOLVER_SUPERLU_LIBRARY)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE(SOLVER_SPOOLES_LIBRARY)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE(SOLVER_UMFPACK_LIBRARY)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE(SOLVER_LUSOL_LIBRARY)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE(SOLVER_ESSL_LIBRARY)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE(SOLVER_LAPACK_LIBRARY)
              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The solver library type of "// &
                & TRIM(NUMBER_TO_VSTRING(LINEAR_DIRECT_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          CASE(SOLVER_DIRECT_CHOLESKY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_DIRECT_SVD)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE DEFAULT
            LOCAL_ERROR="The direct solver type of "// &
              & TRIM(NUMBER_TO_VSTRING(LINEAR_DIRECT_SOLVER%DIRECT_SOLVER_TYPE,"*",ERR,ERROR))// &
              & " is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("Linear solver solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Linear direct solver linear solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Linear direct solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_DIRECT_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_CREATE_FINISH")
    RETURN 1
    
  END SUBROUTINE SOLVER_LINEAR_DIRECT_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Finalise a direct linear solver for a linear solver and deallocate all memory.
  SUBROUTINE SOLVER_LINEAR_DIRECT_FINALISE(LINEAR_DIRECT_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: LINEAR_DIRECT_SOLVER !<A pointer to the lienar direct solver to finalise
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_LINEAR_DIRECT_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_DIRECT_SOLVER)) THEN
      LINEAR_SOLVER=>LINEAR_DIRECT_SOLVER%LINEAR_SOLVER
      IF(ASSOCIATED(LINEAR_SOLVER)) THEN
        IF(.NOT.LINEAR_SOLVER%LINKED_NEWTON_PETSC_SOLVER) THEN
          CALL SOLVER_LINEAR_DIRECT_LU_FINALISE(LINEAR_DIRECT_SOLVER,ERR,ERROR,*999)
        ENDIF
      ENDIF
      DEALLOCATE(LINEAR_DIRECT_SOLVER)
    ENDIF

    CALL EXITS("SOLVER_LINEAR_DIRECT_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a direct linear solver for a lienar solver
  SUBROUTINE SOLVER_LINEAR_DIRECT_INITIALISE(LINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER !<A pointer the linear solver to initialise the direct solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_DIRECT_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(LINEAR_SOLVER)) THEN
      IF(ASSOCIATED(LINEAR_SOLVER%DIRECT_SOLVER)) THEN
        CALL FLAG_ERROR("Direct solver is already associated for this linear solver.",ERR,ERROR,*998)
      ELSE
        ALLOCATE(LINEAR_SOLVER%DIRECT_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate linear solver direct solver.",ERR,ERROR,*999)
        LINEAR_SOLVER%DIRECT_SOLVER%LINEAR_SOLVER=>LINEAR_SOLVER
        !Default to an LU direct linear solver
        LINEAR_SOLVER%DIRECT_SOLVER%DIRECT_SOLVER_TYPE=SOLVER_DIRECT_LU
        CALL SOLVER_LINEAR_DIRECT_LU_INITIALISE(LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Linear solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_DIRECT_INITIALISE")
    RETURN
999 CALL SOLVER_LINEAR_DIRECT_FINALISE(LINEAR_SOLVER%DIRECT_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_LINEAR_DIRECT_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for a direct linear solver.
  SUBROUTINE SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_GET(DIRECT_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER !<A pointer the direct linear solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On exit, the type of library used for the direct linear solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
 
    CALL ENTERS("SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(DIRECT_SOLVER)) THEN
      SELECT CASE(DIRECT_SOLVER%DIRECT_SOLVER_TYPE)
      CASE(SOLVER_DIRECT_LU)
        SOLVER_LIBRARY_TYPE=DIRECT_SOLVER%SOLVER_LIBRARY
      CASE(SOLVER_DIRECT_CHOLESKY)
        SOLVER_LIBRARY_TYPE=DIRECT_SOLVER%SOLVER_LIBRARY
      CASE(SOLVER_DIRECT_SVD)
        SOLVER_LIBRARY_TYPE=DIRECT_SOLVER%SOLVER_LIBRARY
      CASE DEFAULT
        LOCAL_ERROR="The direct linear solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(DIRECT_SOLVER%DIRECT_SOLVER_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Direct linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library to use for a direct linear solver.
  SUBROUTINE SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_SET(DIRECT_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER !<A pointer the direct linear solver to get the library type for.
    INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library for the direct linear solver to set. \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(DIRECT_SOLVER)) THEN
      SELECT CASE(DIRECT_SOLVER%DIRECT_SOLVER_TYPE)
      CASE(SOLVER_DIRECT_LU)
        SELECT CASE(SOLVER_LIBRARY_TYPE)
        CASE(SOLVER_CMISS_LIBRARY)
          CALL FLAG_ERROR("Not implemeted.",ERR,ERROR,*999)
        CASE(SOLVER_MUMPS_LIBRARY)
          DIRECT_SOLVER%SOLVER_LIBRARY=SOLVER_MUMPS_LIBRARY
          DIRECT_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
        CASE(SOLVER_SUPERLU_LIBRARY)
          CALL FLAG_ERROR("Not implemeted.",ERR,ERROR,*999)
        CASE(SOLVER_SPOOLES_LIBRARY)
          CALL FLAG_ERROR("Not implemeted.",ERR,ERROR,*999)
        CASE(SOLVER_LUSOL_LIBRARY)
          CALL FLAG_ERROR("Not implemeted.",ERR,ERROR,*999)
        CASE(SOLVER_ESSL_LIBRARY)
          CALL FLAG_ERROR("Not implemeted.",ERR,ERROR,*999)
        CASE(SOLVER_LAPACK_LIBRARY)
          CALL FLAG_ERROR("Not implemeted.",ERR,ERROR,*999)
        CASE DEFAULT
          LOCAL_ERROR="The specified solver library type of "// &
            & TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
            & " is invalid for a LU direct linear solver."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)            
        END SELECT
      CASE(SOLVER_DIRECT_CHOLESKY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_DIRECT_SVD)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The direct linear solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(DIRECT_SOLVER%DIRECT_SOLVER_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Direct linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Finalise a LU direct linear solver and deallocate all memory.
  SUBROUTINE SOLVER_LINEAR_DIRECT_LU_FINALISE(DIRECT_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER !<A pointer to the linear direct solver to finalise the LU solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LINEAR_DIRECT_LU_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DIRECT_SOLVER)) THEN
      SELECT CASE(DIRECT_SOLVER%SOLVER_LIBRARY)
      CASE(SOLVER_CMISS_LIBRARY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_MUMPS_LIBRARY)
        !Call MUMPS through PETSc
        CALL PETSC_PCFINALISE(DIRECT_SOLVER%PC,ERR,ERROR,*999)
        CALL PETSC_KSPFINALISE(DIRECT_SOLVER%KSP,ERR,ERROR,*999)
      CASE(SOLVER_SUPERLU_LIBRARY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_SPOOLES_LIBRARY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_UMFPACK_LIBRARY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_LUSOL_LIBRARY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_ESSL_LIBRARY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_LAPACK_LIBRARY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The solver library type of "// &
          & TRIM(NUMBER_TO_VSTRING(DIRECT_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))// &
          & " is invalid for a LU direct linear solver."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ENDIF

    CALL EXITS("SOLVER_LINEAR_DIRECT_LU_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_LU_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_LU_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_LU_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a LU direct linear solver for a direct linear solver.
  SUBROUTINE SOLVER_LINEAR_DIRECT_LU_INITIALISE(DIRECT_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER !<A pointer the direct linear solver to initialise the LU direct linear solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_DIRECT_LU_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(DIRECT_SOLVER)) THEN
      !Default to MUMPS library
      DIRECT_SOLVER%SOLVER_LIBRARY=SOLVER_MUMPS_LIBRARY
      !Call MUMPS through PETSc
      DIRECT_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
      CALL PETSC_PCINITIALISE(DIRECT_SOLVER%PC,ERR,ERROR,*999)
      CALL PETSC_KSPINITIALISE(DIRECT_SOLVER%KSP,ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Direct linear solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_DIRECT_LU_INITIALISE")
    RETURN
999 CALL SOLVER_LINEAR_DIRECT_LU_FINALISE(DIRECT_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_LINEAR_DIRECT_LU_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_LU_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_LU_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for a direct linear solver matrices.
  SUBROUTINE SOLVER_LINEAR_DIRECT_MATRICES_LIBRARY_TYPE_GET(DIRECT_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER !<A pointer the direct linear solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: MATRICES_LIBRARY_TYPE !<On exit, the type of library used for the direct linear solver \see DISTRIBUTED_MATRIX_VECTOR_LibraryTypes,DISTRIBUTED_MATRIX_VECTOR
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
 
    CALL ENTERS("SOLVER_LINEAR_DIRECT_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(DIRECT_SOLVER)) THEN
      MATRICES_LIBRARY_TYPE=DIRECT_SOLVER%SOLVER_MATRICES_LIBRARY
    ELSE
      CALL FLAG_ERROR("Direct linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_DIRECT_MATRICES_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_MATRICES_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_MATRICES_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Solve a linear direct solver 
  SUBROUTINE SOLVER_LINEAR_DIRECT_SOLVE(LINEAR_DIRECT_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: LINEAR_DIRECT_SOLVER !<A pointer to the linear direct solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: global_row,local_row,STORAGE_TYPE
    REAL(DP) :: SOLVER_VALUE,VALUE
    REAL(DP), POINTER :: RHS_DATA(:)
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: RHS_VECTOR,SOLVER_VECTOR
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ROW_DOFS_MAPPING
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(SOLVER_MATRIX_TYPE), POINTER :: SOLVER_MATRIX
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LINEAR_DIRECT_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_DIRECT_SOLVER)) THEN
      LINEAR_SOLVER=>LINEAR_DIRECT_SOLVER%LINEAR_SOLVER
      IF(ASSOCIATED(LINEAR_SOLVER)) THEN
        SOLVER=>LINEAR_SOLVER%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
          SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
          IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
            SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
            IF(ASSOCIATED(SOLVER_MATRICES)) THEN
              IF(SOLVER_MATRICES%NUMBER_OF_MATRICES==1) THEN
                SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(1)%PTR
                IF(ASSOCIATED(SOLVER_MATRIX)) THEN
                  RHS_VECTOR=>SOLVER_MATRICES%RHS_VECTOR
                  IF(ASSOCIATED(RHS_VECTOR)) THEN
                    SOLVER_VECTOR=>SOLVER_MATRICES%MATRICES(1)%PTR%SOLVER_VECTOR
                    IF(ASSOCIATED(SOLVER_VECTOR)) THEN
                      CALL DISTRIBUTED_MATRIX_STORAGE_TYPE_GET(SOLVER_MATRIX%MATRIX,STORAGE_TYPE,ERR,ERROR,*999)
                      IF(STORAGE_TYPE==DISTRIBUTED_MATRIX_DIAGONAL_STORAGE_TYPE) THEN
                        SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
                        IF(ASSOCIATED(SOLVER_MAPPING)) THEN
                          ROW_DOFS_MAPPING=>SOLVER_MAPPING%ROW_DOFS_MAPPING
                          IF(ASSOCIATED(ROW_DOFS_MAPPING)) THEN
                            CALL DISTRIBUTED_VECTOR_DATA_GET(RHS_VECTOR,RHS_DATA,ERR,ERROR,*999)
                            DO local_row=1,SOLVER_MAPPING%NUMBER_OF_ROWS
                              global_row=ROW_DOFS_MAPPING%LOCAL_TO_GLOBAL_MAP(local_row)
                              CALL DISTRIBUTED_MATRIX_VALUES_GET(SOLVER_MATRIX%MATRIX,local_row,global_row,VALUE,ERR,ERROR,*999)
                              IF(ABS(VALUE)>ZERO_TOLERANCE) THEN
                                SOLVER_VALUE=RHS_DATA(local_row)/VALUE
                                CALL DISTRIBUTED_VECTOR_VALUES_SET(SOLVER_VECTOR,local_row,SOLVER_VALUE,ERR,ERROR,*999)
                              ELSE
                                LOCAL_ERROR="The linear solver matrix has a zero pivot on row "// &
                                  & TRIM(NUMBER_TO_VSTRING(local_row,"*",ERR,ERROR))//"."
                                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                              ENDIF
                            ENDDO !matrix_idx
                            CALL DISTRIBUTED_VECTOR_DATA_RESTORE(RHS_VECTOR,RHS_DATA,ERR,ERROR,*999)
                          ELSE
                            CALL FLAG_ERROR("Solver mapping row dofs mapping is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Solver equations solver mapping is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        SELECT CASE(LINEAR_DIRECT_SOLVER%DIRECT_SOLVER_TYPE)
                        CASE(SOLVER_DIRECT_LU)                         
                          SELECT CASE(LINEAR_DIRECT_SOLVER%SOLVER_LIBRARY)
                          CASE(SOLVER_CMISS_LIBRARY)
                            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                          CASE(SOLVER_MUMPS_LIBRARY)
                            !Call MUMPS through PETSc
                            IF(ASSOCIATED(RHS_VECTOR%PETSC)) THEN
                              IF(ASSOCIATED(SOLVER_VECTOR%PETSC)) THEN
                                IF(ASSOCIATED(SOLVER_MATRIX%MATRIX)) THEN
                                  IF(ASSOCIATED(SOLVER_MATRIX%MATRIX%PETSC)) THEN
                                    IF(SOLVER_MATRIX%UPDATE_MATRIX) THEN
                                      CALL PETSC_KSPSETOPERATORS(LINEAR_DIRECT_SOLVER%KSP,SOLVER_MATRIX%MATRIX%PETSC%MATRIX, &
                                        & SOLVER_MATRIX%MATRIX%PETSC%MATRIX,PETSC_SAME_NONZERO_PATTERN,ERR,ERROR,*999)
                                    ELSE
                                      CALL PETSC_KSPSETOPERATORS(LINEAR_DIRECT_SOLVER%KSP,SOLVER_MATRIX%MATRIX%PETSC%MATRIX, &
                                        & SOLVER_MATRIX%MATRIX%PETSC%MATRIX,PETSC_SAME_PRECONDITIONER,ERR,ERROR,*999)
                                    ENDIF
                                    !Solve the linear system
                                    CALL PETSC_KSPSOLVE(LINEAR_DIRECT_SOLVER%KSP,RHS_VECTOR%PETSC%VECTOR, &
                                      & SOLVER_VECTOR%PETSC%VECTOR,ERR,ERROR,*999) 
                                  ELSE
                                    CALL FLAG_ERROR("Solver matrix PETSc is not associated.",ERR,ERROR,*999)
                                  ENDIF
                                ELSE
                                   CALL FLAG_ERROR("Solver matrix distributed matrix is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                CALL FLAG_ERROR("Solver vector PETSc vector is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              CALL FLAG_ERROR("RHS vector petsc PETSc is not associated.",ERR,ERROR,*999)
                            ENDIF
                          CASE(SOLVER_SUPERLU_LIBRARY)
                            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                          CASE(SOLVER_SPOOLES_LIBRARY)
                            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                          CASE(SOLVER_UMFPACK_LIBRARY)
                            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                          CASE(SOLVER_LUSOL_LIBRARY)
                            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                          CASE(SOLVER_ESSL_LIBRARY)
                            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                          CASE(SOLVER_LAPACK_LIBRARY)
                            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                          CASE DEFAULT
                            LOCAL_ERROR="The solver library type of "// &
                              & TRIM(NUMBER_TO_VSTRING(LINEAR_DIRECT_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))// &
                              & " is invalid for a LU direct linear solver."
                            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                          END SELECT
                        CASE(SOLVER_DIRECT_CHOLESKY)
                          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                        CASE(SOLVER_DIRECT_SVD)
                          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                        CASE DEFAULT
                          LOCAL_ERROR="The direct linear solver type of "// &
                            & TRIM(NUMBER_TO_VSTRING(LINEAR_DIRECT_SOLVER%DIRECT_SOLVER_TYPE,"*",ERR,ERROR))// &
                            & " is invalid."
                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                        END SELECT
                      ENDIF
                    ELSE
                      CALL FLAG_ERROR("Solver vector is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("RHS vector is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("Solver matrix is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                LOCAL_ERROR="The number of solver matrices of "// &
                  & TRIM(NUMBER_TO_VSTRING(SOLVER_MATRICES%NUMBER_OF_MATRICES,"*",ERR,ERROR))// &
                  & " is invalid. There should only be one solver matrix for a linear direct solver."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver equations solver matrices is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Linear solver solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Linear direct solver linear solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Linear direct solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_DIRECT_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_SOLVE")
    RETURN 1
    
  END SUBROUTINE SOLVER_LINEAR_DIRECT_SOLVE
        
  !
  !================================================================================================================================
  !

  !>Finalise a SVD direct linear solver and deallocate all memory.
  SUBROUTINE SOLVER_LINEAR_DIRECT_SVD_FINALISE(LINEAR_DIRECT_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: LINEAR_DIRECT_SOLVER !<A pointer to the linear direct solver to finalise the SVD solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_LINEAR_DIRECT_SVD_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_DIRECT_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("SOLVER_LINEAR_DIRECT_SVD_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_SVD_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_SVD_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_SVD_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a SVD direct linear solver for a direct linear solver.
  SUBROUTINE SOLVER_LINEAR_DIRECT_SVD_INITIALISE(DIRECT_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER !<A pointer the direct linear solver to initialise the SVD direct linear solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    
    CALL ENTERS("SOLVER_LINEAR_DIRECT_SVD_INITIALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(DIRECT_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Direct linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_DIRECT_SVD_INITIALISE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_SVD_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_SVD_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_SVD_INITIALISE

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of direct linear solver. \see OPENCMISS::CMISSSolverLinearDirectTypeSet
  SUBROUTINE SOLVER_LINEAR_DIRECT_TYPE_SET(SOLVER,DIRECT_SOLVER_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the direct linear solver type for.
    INTEGER(INTG), INTENT(IN) :: DIRECT_SOLVER_TYPE !<The type of direct linear solver to set \see SOLVER_ROUTINES_DirectLinearSolverTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_DIRECT_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_LINEAR_TYPE) THEN
          IF(ASSOCIATED(SOLVER%LINEAR_SOLVER)) THEN
            IF(SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE==SOLVER_LINEAR_DIRECT_SOLVE_TYPE) THEN
              IF(ASSOCIATED(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER)) THEN
                IF(DIRECT_SOLVER_TYPE/=SOLVER%LINEAR_SOLVER%DIRECT_SOLVER%DIRECT_SOLVER_TYPE) THEN
                  !Finalise the old direct solver
                  SELECT CASE(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER%SOLVER_LIBRARY)
                  CASE(SOLVER_DIRECT_LU)
                    CALL SOLVER_LINEAR_DIRECT_LU_FINALISE(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
                  CASE(SOLVER_DIRECT_CHOLESKY)
                    CALL SOLVER_LINEAR_DIRECT_CHOLESKY_FINALISE(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
                  CASE(SOLVER_DIRECT_SVD)
                    CALL SOLVER_LINEAR_DIRECT_SVD_FINALISE(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
                  CASE DEFAULT
                    LOCAL_ERROR="The direct solver type of "//TRIM(NUMBER_TO_VSTRING(DIRECT_SOLVER_TYPE,"*",ERR,ERROR))// &
                      & " is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT
                  !Initialise the new library
                  SELECT CASE(DIRECT_SOLVER_TYPE)
                  CASE(SOLVER_DIRECT_LU)
                    CALL SOLVER_LINEAR_DIRECT_LU_INITIALISE(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
                  CASE(SOLVER_DIRECT_CHOLESKY)
                    CALL SOLVER_LINEAR_DIRECT_CHOLESKY_INITIALISE(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
                  CASE(SOLVER_DIRECT_SVD)
                    CALL SOLVER_LINEAR_DIRECT_SVD_INITIALISE(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
                  CASE DEFAULT
                    LOCAL_ERROR="The direct solver type of "//TRIM(NUMBER_TO_VSTRING(DIRECT_SOLVER_TYPE,"*",ERR,ERROR))// &
                      & " is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT
                ENDIF
              ELSE
                CALL FLAG_ERROR("The solver linear solver direct solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver is not a linear direct solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a linear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_DIRECT_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_DIRECT_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_DIRECT_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_DIRECT_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Finalise a linear solver for a solver.
  SUBROUTINE SOLVER_LINEAR_FINALISE(LINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER !<A pointer the linear solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_LINEAR_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_SOLVER)) THEN
      CALL SOLVER_LINEAR_DIRECT_FINALISE(LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_LINEAR_ITERATIVE_FINALISE(LINEAR_SOLVER%ITERATIVE_SOLVER,ERR,ERROR,*999)
      DEALLOCATE(LINEAR_SOLVER)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a linear solver for a solver.
  SUBROUTINE SOLVER_LINEAR_INITIALISE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to initialise the linear solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    CALL ENTERS("SOLVER_LINEAR_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(ASSOCIATED(SOLVER%LINEAR_SOLVER)) THEN
        CALL FLAG_ERROR("Linear solver is already associated for this solver.",ERR,ERROR,*998)
      ELSE
        !Allocate and initialise a linear solver
        ALLOCATE(SOLVER%LINEAR_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver linear solver.",ERR,ERROR,*999)
        SOLVER%LINEAR_SOLVER%SOLVER=>SOLVER
        SOLVER%LINEAR_SOLVER%LINKED_NEWTON_PETSC_SOLVER=.FALSE.
        NULLIFY(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER)
        NULLIFY(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER)
        !Default to a iterative solver
        SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE=SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE
        CALL SOLVER_LINEAR_ITERATIVE_INITIALISE(SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_INITIALISE")
    RETURN
999 CALL SOLVER_LINEAR_FINALISE(SOLVER%LINEAR_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_LINEAR_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_INITIALISE

  !
  !================================================================================================================================
  !

  !>Sets/changes the maximum absolute tolerance for an iterative linear solver. \see OPENCMISS::CMISSSolverLinearIterativeAbsoluteToleranceSet
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_ABSOLUTE_TOLERANCE_SET(SOLVER,ABSOLUTE_TOLERANCE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set 
    REAL(DP), INTENT(IN) :: ABSOLUTE_TOLERANCE !<The absolute tolerance to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_ABSOLUTE_TOLERANCE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_LINEAR_TYPE) THEN
          IF(ASSOCIATED(SOLVER%LINEAR_SOLVER)) THEN
            IF(SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE==SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE) THEN
              IF(ASSOCIATED(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER)) THEN
                IF(ABSOLUTE_TOLERANCE>ZERO_TOLERANCE) THEN
                  SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ABSOLUTE_TOLERANCE=ABSOLUTE_TOLERANCE
                ELSE
                  LOCAL_ERROR="The specified absolute tolerance of "//TRIM(NUMBER_TO_VSTRING(ABSOLUTE_TOLERANCE,"*",ERR,ERROR))// &
                    & " is invalid. The absolute tolerance must be > 0."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The solver linear solver iterative solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver is not a linear iterative solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a linear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_ABSOLUTE_TOLERANCE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_ABSOLUTE_TOLERANCE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_ABSOLUTE_TOLERANCE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_ABSOLUTE_TOLERANCE_SET
        
  !
  !================================================================================================================================
  !

  !>Finishes the process of creating a linear iterative solver 
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_CREATE_FINISH(LINEAR_ITERATIVE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_ITERATIVE_SOLVER_TYPE), POINTER :: LINEAR_ITERATIVE_SOLVER !<A pointer to the linear iterative solver to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(DISTRIBUTED_MATRIX_TYPE), POINTER :: SOLVER_MATRIX
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER
    TYPE(NEWTON_TRUSTREGION_SOLVER_TYPE), POINTER :: TRUSTREGION_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(SOLVER_TYPE), POINTER :: LINKING_SOLVER,SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_ITERATIVE_SOLVER)) THEN
      LINEAR_SOLVER=>LINEAR_ITERATIVE_SOLVER%LINEAR_SOLVER
      IF(ASSOCIATED(LINEAR_SOLVER)) THEN
        SOLVER=>LINEAR_SOLVER%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
          !Should really check iterative types here and then the solver library but as they are all PETSc for now hold off.
          SELECT CASE(LINEAR_ITERATIVE_SOLVER%SOLVER_LIBRARY)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
              SOLVER_EQUATIONS=>SOLVER%LINKING_SOLVER%SOLVER_EQUATIONS
              IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
                SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
                IF(.NOT.ASSOCIATED(SOLVER_MATRICES)) &
                  & CALL FLAG_ERROR("Linked solver equation solver matrices is not associated.",ERR,ERROR,*999)
              ELSE
                CALL FLAG_ERROR("Linked solver solver equations is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
              IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
                !Create the solver matrices and vectors
                NULLIFY(SOLVER_MATRICES)
                CALL SOLVER_MATRICES_CREATE_START(SOLVER_EQUATIONS,SOLVER_MATRICES,ERR,ERROR,*999)
                CALL SOLVER_MATRICES_LIBRARY_TYPE_SET(SOLVER_MATRICES,SOLVER_PETSC_LIBRARY,ERR,ERROR,*999)
                SELECT CASE(SOLVER_EQUATIONS%SPARSITY_TYPE)
                CASE(SOLVER_SPARSE_MATRICES)
                  CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_COMPRESSED_ROW_STORAGE_TYPE/), &
                    & ERR,ERROR,*999)
                CASE(SOLVER_FULL_MATRICES)
                  CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_BLOCK_STORAGE_TYPE/), &
                    & ERR,ERROR,*999)
                CASE DEFAULT
                  LOCAL_ERROR="The specified solver equations sparsity type of "// &
                    & TRIM(NUMBER_TO_VSTRING(SOLVER_EQUATIONS%SPARSITY_TYPE,"*",ERR,ERROR))// &
                    & " is invalid."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                END SELECT
                CALL SOLVER_MATRICES_CREATE_FINISH(SOLVER_MATRICES,ERR,ERROR,*999)
              ELSE
                CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
              ENDIF
            ENDIF
            !Create the PETSc KSP solver
            IF(LINEAR_SOLVER%LINKED_NEWTON_PETSC_SOLVER) THEN
              LINKING_SOLVER=>SOLVER%LINKING_SOLVER
              IF(ASSOCIATED(LINKING_SOLVER)) THEN
                NONLINEAR_SOLVER=>LINKING_SOLVER%NONLINEAR_SOLVER
                IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
                  NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
                  IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                    SELECT CASE(NEWTON_SOLVER%NEWTON_SOLVE_TYPE)
                    CASE(SOLVER_NEWTON_LINESEARCH)
                      LINESEARCH_SOLVER=>NEWTON_SOLVER%LINESEARCH_SOLVER
                      IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
                        CALL PETSC_SNESGETKSP(LINESEARCH_SOLVER%SNES,LINEAR_ITERATIVE_SOLVER%KSP,ERR,ERROR,*999)
                      ELSE
                        CALL FLAG_ERROR("Newton solver linesearch solver is not associated.",ERR,ERROR,*999)
                      ENDIF
                    CASE(SOLVER_NEWTON_TRUSTREGION)
                      TRUSTREGION_SOLVER=>NEWTON_SOLVER%TRUSTREGION_SOLVER
                      IF(ASSOCIATED(TRUSTREGION_SOLVER)) THEN
                        CALL PETSC_SNESGETKSP(TRUSTREGION_SOLVER%SNES,LINEAR_ITERATIVE_SOLVER%KSP,ERR,ERROR,*999)
                      ELSE
                        CALL FLAG_ERROR("Newton solver linesearch solver is not associated.",ERR,ERROR,*999)
                      ENDIF
                    CASE DEFAULT
                      LOCAL_ERROR="The Newton solve type of "// &
                        & TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVER%NEWTON_SOLVE_TYPE,"*",ERR,ERROR))//"is invalid."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    END SELECT
                  ELSE
                    CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("Linking solver nonlinear solver is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("Solver linke solve is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL PETSC_KSPCREATE(COMPUTATIONAL_ENVIRONMENT%MPI_COMM,LINEAR_ITERATIVE_SOLVER%KSP,ERR,ERROR,*999)
            ENDIF
            !Set the iterative solver type
            SELECT CASE(LINEAR_ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE)
            CASE(SOLVER_ITERATIVE_RICHARDSON)
              CALL PETSC_KSPSETTYPE(LINEAR_ITERATIVE_SOLVER%KSP,PETSC_KSPRICHARDSON,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_CHEBYCHEV)
              CALL PETSC_KSPSETTYPE(LINEAR_ITERATIVE_SOLVER%KSP,PETSC_KSPCHEBYCHEV,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_CONJUGATE_GRADIENT)
              CALL PETSC_KSPSETTYPE(LINEAR_ITERATIVE_SOLVER%KSP,PETSC_KSPCG,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_BICONJUGATE_GRADIENT)
              CALL PETSC_KSPSETTYPE(LINEAR_ITERATIVE_SOLVER%KSP,PETSC_KSPBICG,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_GMRES)
              CALL PETSC_KSPSETTYPE(LINEAR_ITERATIVE_SOLVER%KSP,PETSC_KSPGMRES,ERR,ERROR,*999)
              CALL PETSC_KSPGMRESSETRESTART(LINEAR_ITERATIVE_SOLVER%KSP,LINEAR_ITERATIVE_SOLVER%GMRES_RESTART,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_BiCGSTAB)
              CALL PETSC_KSPSETTYPE(LINEAR_ITERATIVE_SOLVER%KSP,PETSC_KSPBCGS,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_CONJGRAD_SQUARED)
              CALL PETSC_KSPSETTYPE(LINEAR_ITERATIVE_SOLVER%KSP,PETSC_KSPCGS,ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The iterative solver type of "// &
                & TRIM(NUMBER_TO_VSTRING(LINEAR_ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
            !Get the pre-conditioner
            CALL PETSC_KSPGETPC(LINEAR_ITERATIVE_SOLVER%KSP,LINEAR_ITERATIVE_SOLVER%PC,ERR,ERROR,*999)
            !Set the pre-conditioner type
            SELECT CASE(LINEAR_ITERATIVE_SOLVER%ITERATIVE_PRECONDITIONER_TYPE)
            CASE(SOLVER_ITERATIVE_NO_PRECONDITIONER)
              CALL PETSC_PCSETTYPE(LINEAR_ITERATIVE_SOLVER%PC,PETSC_PCNONE,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_JACOBI_PRECONDITIONER)
              CALL PETSC_PCSETTYPE(LINEAR_ITERATIVE_SOLVER%PC,PETSC_PCJACOBI,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_BLOCK_JACOBI_PRECONDITIONER)
              CALL PETSC_PCSETTYPE(LINEAR_ITERATIVE_SOLVER%PC,PETSC_PCBJACOBI,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_SOR_PRECONDITIONER)
              CALL PETSC_PCSETTYPE(LINEAR_ITERATIVE_SOLVER%PC,PETSC_PCSOR,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_INCOMPLETE_CHOLESKY_PRECONDITIONER)
              CALL PETSC_PCSETTYPE(LINEAR_ITERATIVE_SOLVER%PC,PETSC_PCICC,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_INCOMPLETE_LU_PRECONDITIONER)
              CALL PETSC_PCSETTYPE(LINEAR_ITERATIVE_SOLVER%PC,PETSC_PCILU,ERR,ERROR,*999)
            CASE(SOLVER_ITERATIVE_ADDITIVE_SCHWARZ_PRECONDITIONER)
              CALL PETSC_PCSETTYPE(LINEAR_ITERATIVE_SOLVER%PC,PETSC_PCASM,ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The iterative preconditioner type of "// &
                & TRIM(NUMBER_TO_VSTRING(LINEAR_ITERATIVE_SOLVER%ITERATIVE_PRECONDITIONER_TYPE,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
            !Set the tolerances for the KSP solver
            CALL PETSC_KSPSETTOLERANCES(LINEAR_ITERATIVE_SOLVER%KSP,LINEAR_ITERATIVE_SOLVER%RELATIVE_TOLERANCE, &
              & LINEAR_ITERATIVE_SOLVER%ABSOLUTE_TOLERANCE,LINEAR_ITERATIVE_SOLVER%DIVERGENCE_TOLERANCE, &
              & LINEAR_ITERATIVE_SOLVER%MAXIMUM_NUMBER_OF_ITERATIONS,ERR,ERROR,*999)
            !Set any further KSP options from the command line options
            CALL PETSC_KSPSETFROMOPTIONS(LINEAR_ITERATIVE_SOLVER%KSP,ERR,ERROR,*999)
            !Set the solver matrix to be the KSP matrix
            IF(SOLVER_MATRICES%NUMBER_OF_MATRICES==1) THEN
              SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(1)%PTR%MATRIX
              IF(ASSOCIATED(SOLVER_MATRIX)) THEN
                IF(ASSOCIATED(SOLVER_MATRIX%PETSC)) THEN
                  CALL PETSC_KSPSETOPERATORS(LINEAR_ITERATIVE_SOLVER%KSP,SOLVER_MATRIX%PETSC%MATRIX,SOLVER_MATRIX%PETSC%MATRIX, &
                    & PETSC_DIFFERENT_NONZERO_PATTERN,ERR,ERROR,*999)
                ELSE
                  CALL FLAG_ERROR("Solver matrix PETSc is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("Solver matrices distributed matrix is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              LOCAL_ERROR="The given number of solver matrices of "// &
                & TRIM(NUMBER_TO_VSTRING(SOLVER_MATRICES%NUMBER_OF_MATRICES,"*",ERR,ERROR))// &
                & " is invalid. There should only be one solver matrix for a linear iterative solver."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            ENDIF
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "// &
              & TRIM(NUMBER_TO_VSTRING(LINEAR_ITERATIVE_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))//" is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("Linear solver solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Linear iterative solver linear solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Linear iterative solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_CREATE_FINISH")
    RETURN 1
    
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the maximum divergence tolerance for an iterative linear solver. \see OPENCMISS::CMISSSolverLinearIterativeDivergenceToleranceSet
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_DIVERGENCE_TOLERANCE_SET(SOLVER,DIVERGENCE_TOLERANCE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set 
    REAL(DP), INTENT(IN) :: DIVERGENCE_TOLERANCE !<The divergence tolerance to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_DIVERGENCE_TOLERANCE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_LINEAR_TYPE) THEN
          IF(ASSOCIATED(SOLVER%LINEAR_SOLVER)) THEN
            IF(SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE==SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE) THEN
              IF(ASSOCIATED(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER)) THEN
                IF(DIVERGENCE_TOLERANCE>ZERO_TOLERANCE) THEN
                  SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%DIVERGENCE_TOLERANCE=DIVERGENCE_TOLERANCE
                ELSE
                  LOCAL_ERROR="The specified divergence tolerance of "// &
                    & TRIM(NUMBER_TO_VSTRING(DIVERGENCE_TOLERANCE,"*",ERR,ERROR))// &
                    & " is invalid. The divergence tolerance must be > 0."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The solver linear solver iterative solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver is not a linear iterative solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a linear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_DIVERGENCE_TOLERANCE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_DIVERGENCE_TOLERANCE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_DIVERGENCE_TOLERANCE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_DIVERGENCE_TOLERANCE_SET
        
  !
  !================================================================================================================================
  !

  !>Finalise an iterative linear solver for a linear solver and deallocate all memory.
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_FINALISE(LINEAR_ITERATIVE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_ITERATIVE_SOLVER_TYPE), POINTER :: LINEAR_ITERATIVE_SOLVER !<A pointer the linear iterative solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER

    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_ITERATIVE_SOLVER)) THEN
      LINEAR_SOLVER=>LINEAR_ITERATIVE_SOLVER%LINEAR_SOLVER
      IF(ASSOCIATED(LINEAR_SOLVER)) THEN
        IF(.NOT.LINEAR_SOLVER%LINKED_NEWTON_PETSC_SOLVER) THEN
          CALL PETSC_PCFINALISE(LINEAR_ITERATIVE_SOLVER%PC,ERR,ERROR,*999)
          CALL PETSC_KSPFINALISE(LINEAR_ITERATIVE_SOLVER%KSP,ERR,ERROR,*999)
        ENDIF
      ENDIF
      DEALLOCATE(LINEAR_ITERATIVE_SOLVER)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_FINALISE

  !
  !================================================================================================================================
  !

  !>Sets/changes the GMRES restart value for a GMRES iterative linear solver. \see OPENCMISS::CMISSSolverLinearIterativeGMRESRestartSet
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_GMRES_RESTART_SET(SOLVER,GMRES_RESTART,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the GMRES restart value
    INTEGER(INTG), INTENT(IN) :: GMRES_RESTART !<The GMRES restart value
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER
    TYPE(LINEAR_ITERATIVE_SOLVER_TYPE), POINTER :: ITERATIVE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_GMRES_RESTART_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_LINEAR_TYPE) THEN
          LINEAR_SOLVER=>SOLVER%LINEAR_SOLVER
          IF(ASSOCIATED(LINEAR_SOLVER)) THEN
            IF(LINEAR_SOLVER%LINEAR_SOLVE_TYPE==SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE) THEN
              ITERATIVE_SOLVER=>LINEAR_SOLVER%ITERATIVE_SOLVER
              IF(ASSOCIATED(ITERATIVE_SOLVER)) THEN
                IF(ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE==SOLVER_ITERATIVE_GMRES) THEN
                  IF(GMRES_RESTART>0) THEN
                    ITERATIVE_SOLVER%GMRES_RESTART=GMRES_RESTART
                  ELSE
                    LOCAL_ERROR="The specified GMRES restart value of "//TRIM(NUMBER_TO_VSTRING(GMRES_RESTART,"*",ERR,ERROR))// &
                      & " is invalid. The GMRES restart value must be > 0."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("The linear iterative solver is not a GMRES linear iterative solver.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The solver linear solver iterative solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver is not a linear iterative solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a linear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_GMRES_RESTART_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_GMRES_RESTART_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_GMRES_RESTART_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_GMRES_RESTART_SET
        
  !
  !================================================================================================================================
  !

  !>Initialise an iterative linear solver for a linear solver
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_INITIALISE(LINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER !<A pointer the linear solver to initialise the iterative solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(LINEAR_SOLVER)) THEN
      IF(ASSOCIATED(LINEAR_SOLVER%ITERATIVE_SOLVER)) THEN
        CALL FLAG_ERROR("Iterative solver is already associated for this linear solver.",ERR,ERROR,*998)
      ELSE
        !Allocate and initialise a iterative solver
        ALLOCATE(LINEAR_SOLVER%ITERATIVE_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate linear solver iterative solver.",ERR,ERROR,*999)
        LINEAR_SOLVER%ITERATIVE_SOLVER%LINEAR_SOLVER=>LINEAR_SOLVER
        LINEAR_SOLVER%ITERATIVE_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
        LINEAR_SOLVER%ITERATIVE_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
        LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE=SOLVER_ITERATIVE_GMRES
        LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_PRECONDITIONER_TYPE=SOLVER_ITERATIVE_JACOBI_PRECONDITIONER
        LINEAR_SOLVER%ITERATIVE_SOLVER%SOLUTION_INITIALISE_TYPE=SOLVER_SOLUTION_INITIALISE_CURRENT_FIELD
        LINEAR_SOLVER%ITERATIVE_SOLVER%MAXIMUM_NUMBER_OF_ITERATIONS=100000
        LINEAR_SOLVER%ITERATIVE_SOLVER%RELATIVE_TOLERANCE=1.0E-05_DP
        LINEAR_SOLVER%ITERATIVE_SOLVER%ABSOLUTE_TOLERANCE=1.0E-10_DP
        LINEAR_SOLVER%ITERATIVE_SOLVER%DIVERGENCE_TOLERANCE=1.0E5_DP
        LINEAR_SOLVER%ITERATIVE_SOLVER%GMRES_RESTART=30
        CALL PETSC_PCINITIALISE(LINEAR_SOLVER%ITERATIVE_SOLVER%PC,ERR,ERROR,*999)
        CALL PETSC_KSPINITIALISE(LINEAR_SOLVER%ITERATIVE_SOLVER%KSP,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Linear solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_INITIALISE")
    RETURN
999 CALL SOLVER_LINEAR_ITERATIVE_FINALISE(LINEAR_SOLVER%ITERATIVE_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for an iterative linear solver.
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_GET(ITERATIVE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_ITERATIVE_SOLVER_TYPE), POINTER :: ITERATIVE_SOLVER !<A pointer the iterative linear solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On exit, the type of library used for the iterative linear solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
 
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(ITERATIVE_SOLVER)) THEN
      SELECT CASE(ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE)
      CASE(SOLVER_ITERATIVE_RICHARDSON)
        SOLVER_LIBRARY_TYPE=ITERATIVE_SOLVER%SOLVER_LIBRARY
      CASE(SOLVER_ITERATIVE_CHEBYCHEV)
        SOLVER_LIBRARY_TYPE=ITERATIVE_SOLVER%SOLVER_LIBRARY
      CASE(SOLVER_ITERATIVE_CONJUGATE_GRADIENT)
        SOLVER_LIBRARY_TYPE=ITERATIVE_SOLVER%SOLVER_LIBRARY
      CASE(SOLVER_ITERATIVE_GMRES)
        SOLVER_LIBRARY_TYPE=ITERATIVE_SOLVER%SOLVER_LIBRARY
      CASE(SOLVER_ITERATIVE_BiCGSTAB)
        SOLVER_LIBRARY_TYPE=ITERATIVE_SOLVER%SOLVER_LIBRARY
      CASE(SOLVER_ITERATIVE_CONJGRAD_SQUARED)
        SOLVER_LIBRARY_TYPE=ITERATIVE_SOLVER%SOLVER_LIBRARY
      CASE DEFAULT
        LOCAL_ERROR="The iterative linear solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Iterative linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library to use for an iterative linear solver.
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_SET(ITERATIVE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_ITERATIVE_SOLVER_TYPE), POINTER :: ITERATIVE_SOLVER !<A pointer the iterative linear solver to get the library type for.
    INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library for the iterative linear solver to set. \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(ITERATIVE_SOLVER)) THEN
      SELECT CASE(ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE)
      CASE(SOLVER_ITERATIVE_RICHARDSON)
        SELECT CASE(SOLVER_LIBRARY_TYPE)
        CASE(SOLVER_CMISS_LIBRARY)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE(SOLVER_PETSC_LIBRARY)
          ITERATIVE_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
          ITERATIVE_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
        CASE DEFAULT
          LOCAL_ERROR="The specified solver library type of "// &
            & TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
            & " is invalid for a Richardson iterative linear solver."
        END SELECT
      CASE(SOLVER_ITERATIVE_CHEBYCHEV)
        SELECT CASE(SOLVER_LIBRARY_TYPE)
        CASE(SOLVER_CMISS_LIBRARY)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE(SOLVER_PETSC_LIBRARY)
          ITERATIVE_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
          ITERATIVE_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
       CASE DEFAULT
          LOCAL_ERROR="The specified solver library type of "// &
            & TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
            & " is invalid for a Chebychev iterative linear solver."
        END SELECT
      CASE(SOLVER_ITERATIVE_CONJUGATE_GRADIENT)
        SELECT CASE(SOLVER_LIBRARY_TYPE)
        CASE(SOLVER_CMISS_LIBRARY)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE(SOLVER_PETSC_LIBRARY)
          ITERATIVE_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
          ITERATIVE_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
        CASE DEFAULT
          LOCAL_ERROR="The specified solver library type of "// &
            & TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
            & " is invalid for a Conjugate gradient iterative linear solver."
        END SELECT
      CASE(SOLVER_ITERATIVE_GMRES)
        SELECT CASE(SOLVER_LIBRARY_TYPE)
        CASE(SOLVER_CMISS_LIBRARY)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE(SOLVER_PETSC_LIBRARY)
          ITERATIVE_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
          ITERATIVE_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
       CASE DEFAULT
          LOCAL_ERROR="The specified solver library type of "// &
            & TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
            & " is invalid for a GMRES iterative linear solver."
        END SELECT
      CASE(SOLVER_ITERATIVE_BiCGSTAB)
        SELECT CASE(SOLVER_LIBRARY_TYPE)
        CASE(SOLVER_CMISS_LIBRARY)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE(SOLVER_PETSC_LIBRARY)
          ITERATIVE_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
          ITERATIVE_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
       CASE DEFAULT
          LOCAL_ERROR="The specified solver library type of "// &
            & TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
            & " is invalid for a BiCGSTAB iterative linear solver."
        END SELECT
      CASE(SOLVER_ITERATIVE_CONJGRAD_SQUARED)
        SELECT CASE(SOLVER_LIBRARY_TYPE)
        CASE(SOLVER_CMISS_LIBRARY)
          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
        CASE(SOLVER_PETSC_LIBRARY)
          ITERATIVE_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
          ITERATIVE_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
       CASE DEFAULT
          LOCAL_ERROR="The specified solver library type of "// &
            & TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
            & " is invalid for a Conjugate gradient squared iterative linear solver."
        END SELECT
      CASE DEFAULT
        LOCAL_ERROR="The iterative linear solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Iterative linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for an iterative linear solver matrices.
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_MATRICES_LIBRARY_TYPE_GET(ITERATIVE_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_ITERATIVE_SOLVER_TYPE), POINTER :: ITERATIVE_SOLVER !<A pointer the iterative linear solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: MATRICES_LIBRARY_TYPE !<On exit, the type of library used for the iterative linear solver matrices \see DISTRIBUTED_MATRIX_VECTOR_LibraryTypes,DISTRIBUTED_MATRIX_VECTOR
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(ITERATIVE_SOLVER)) THEN
      MATRICES_LIBRARY_TYPE=ITERATIVE_SOLVER%SOLVER_MATRICES_LIBRARY
    ELSE
      CALL FLAG_ERROR("Iterative linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_MATRICES_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_MATRICES_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_MATRICES_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the maximum number of iterations for an iterative linear solver. \see OPENCMISS::CMISSSolverLinearIterativeMaximumIterationsSet
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_MAXIMUM_ITERATIONS_SET(SOLVER,MAXIMUM_ITERATIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the maximum number of iterations
    INTEGER(INTG), INTENT(IN) :: MAXIMUM_ITERATIONS !<The maximum number of iterations
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_MAXIMUM_ITERATIONS_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_LINEAR_TYPE) THEN
          IF(ASSOCIATED(SOLVER%LINEAR_SOLVER)) THEN
            IF(SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE==SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE) THEN
              IF(ASSOCIATED(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER)) THEN
                IF(MAXIMUM_ITERATIONS>0) THEN
                  SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%MAXIMUM_NUMBER_OF_ITERATIONS=MAXIMUM_ITERATIONS
                ELSE
                  LOCAL_ERROR="The specified maximum iterations of "//TRIM(NUMBER_TO_VSTRING(MAXIMUM_ITERATIONS,"*",ERR,ERROR))// &
                    & " is invalid. The maximum number of iterations must be > 0."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The solver linear solver iterative solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver is not a linear iterative solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a linear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_MAXIMUM_ITERATIONS_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_MAXIMUM_ITERATIONS_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_MAXIMUM_ITERATIONS_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_MAXIMUM_ITERATIONS_SET
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the type of preconditioner for an iterative linear solver. \see OPENCMISS::CMISSSolverLinearIterativePreconditionerTypeSet
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_PRECONDITIONER_TYPE_SET(SOLVER,ITERATIVE_PRECONDITIONER_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the iterative linear solver type
    INTEGER(INTG), INTENT(IN) :: ITERATIVE_PRECONDITIONER_TYPE !<The type of iterative preconditioner to set \see SOLVER_ROUTINES_IterativeLinearSolverTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_PRECONDITIONER_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_LINEAR_TYPE) THEN
          IF(ASSOCIATED(SOLVER%LINEAR_SOLVER)) THEN
            IF(SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE==SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE) THEN
              IF(ASSOCIATED(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER)) THEN
                IF(ITERATIVE_PRECONDITIONER_TYPE/=SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_PRECONDITIONER_TYPE) THEN
                  !Intialise the new preconditioner type
                  SELECT CASE(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%SOLVER_LIBRARY)
                  CASE(SOLVER_PETSC_LIBRARY)
                    SELECT CASE(ITERATIVE_PRECONDITIONER_TYPE)
                    CASE(SOLVER_ITERATIVE_NO_PRECONDITIONER)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_PRECONDITIONER_TYPE=SOLVER_ITERATIVE_NO_PRECONDITIONER
                    CASE(SOLVER_ITERATIVE_JACOBI_PRECONDITIONER)
                      CALL FLAG_ERROR("Iterative Jacobi preconditioning is not implemented for a PETSc library.",ERR,ERROR,*999)
                    CASE(SOLVER_ITERATIVE_BLOCK_JACOBI_PRECONDITIONER)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_PRECONDITIONER_TYPE= &
                        & SOLVER_ITERATIVE_BLOCK_JACOBI_PRECONDITIONER
                    CASE(SOLVER_ITERATIVE_SOR_PRECONDITIONER)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_PRECONDITIONER_TYPE= &
                        & SOLVER_ITERATIVE_SOR_PRECONDITIONER
                    CASE(SOLVER_ITERATIVE_INCOMPLETE_CHOLESKY_PRECONDITIONER)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_PRECONDITIONER_TYPE= &
                        & SOLVER_ITERATIVE_INCOMPLETE_CHOLESKY_PRECONDITIONER 
                    CASE(SOLVER_ITERATIVE_INCOMPLETE_LU_PRECONDITIONER)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_PRECONDITIONER_TYPE= &
                        & SOLVER_ITERATIVE_INCOMPLETE_LU_PRECONDITIONER
                    CASE(SOLVER_ITERATIVE_ADDITIVE_SCHWARZ_PRECONDITIONER)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_PRECONDITIONER_TYPE= &
                        & SOLVER_ITERATIVE_ADDITIVE_SCHWARZ_PRECONDITIONER
                   CASE DEFAULT
                      LOCAL_ERROR="The iterative preconditioner type of "// &
                        & TRIM(NUMBER_TO_VSTRING(ITERATIVE_PRECONDITIONER_TYPE,"*",ERR,ERROR))//" is invalid."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    END SELECT
                  CASE DEFAULT
                    LOCAL_ERROR="The solver library type of "// &
                      & TRIM(NUMBER_TO_VSTRING(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))// &
                      & " is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT                  
                ENDIF
              ELSE
                CALL FLAG_ERROR("The solver linear solver iterative solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver is not a linear iterative solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a linear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_PRECONDITIONER_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_PRECONDITIONER_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_PRECONDITIONER_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_PRECONDITIONER_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the relative tolerance for an iterative linear solver. \see OPENCMISS::CMISSSolverLinearIterativeRelativeToleranceSet
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_RELATIVE_TOLERANCE_SET(SOLVER,RELATIVE_TOLERANCE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set 
    REAL(DP), INTENT(IN) :: RELATIVE_TOLERANCE !<The relative tolerance to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_RELATIVE_TOLERANCE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_LINEAR_TYPE) THEN
          IF(ASSOCIATED(SOLVER%LINEAR_SOLVER)) THEN
            IF(SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE==SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE) THEN
              IF(ASSOCIATED(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER)) THEN
                IF(RELATIVE_TOLERANCE>ZERO_TOLERANCE) THEN
                  SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%RELATIVE_TOLERANCE=RELATIVE_TOLERANCE
                ELSE
                  LOCAL_ERROR="The specified relative tolerance of "//TRIM(NUMBER_TO_VSTRING(RELATIVE_TOLERANCE,"*",ERR,ERROR))// &
                    & " is invalid. The relative tolerance must be > 0."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The solver linear solver iterative solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver is not a linear iterative solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a linear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_RELATIVE_TOLERANCE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_RELATIVE_TOLERANCE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_RELATIVE_TOLERANCE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_RELATIVE_TOLERANCE_SET
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the solution initialise type for an iterative linear solver
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_SOLUTION_INIT_TYPE_SET(SOLVER,SOLUTION_INITIALISE_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set 
    INTEGER(INTG), INTENT(IN) :: SOLUTION_INITIALISE_TYPE !<The solution initialise type to set \see SOLVER_ROUTINES_SolutionInitialiseTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_SOLUTION_INIT_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_LINEAR_TYPE) THEN
          IF(ASSOCIATED(SOLVER%LINEAR_SOLVER)) THEN
            IF(SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE==SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE) THEN
              IF(ASSOCIATED(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER)) THEN
                SELECT CASE(SOLUTION_INITIALISE_TYPE)
                CASE(SOLVER_SOLUTION_INITIALISE_ZERO)
                CASE(SOLVER_SOLUTION_INITIALISE_CURRENT_FIELD)
                CASE(SOLVER_SOLUTION_INITIALISE_NO_CHANGE)
                CASE DEFAULT
                  LOCAL_ERROR="The specified solution initialise type of "// &
                    & TRIM(NUMBER_TO_VSTRING(SOLUTION_INITIALISE_TYPE,"*",ERR,ERROR))//" is invalid."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                END SELECT
              ELSE
                CALL FLAG_ERROR("The solver linear solver iterative solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver is not a linear iterative solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a linear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_SOLUTION_INIT_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_SOLUTION_INIT_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_SOLUTION_INIT_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_SOLUTION_INIT_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Solves a linear iterative linear solver
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_SOLVE(LINEAR_ITERATIVE_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_ITERATIVE_SOLVER_TYPE), POINTER :: LINEAR_ITERATIVE_SOLVER !<A pointer the linear iterative solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: CONVERGED_REASON,global_row,local_row,NUMBER_ITERATIONS,STORAGE_TYPE
    REAL(DP) :: RESIDUAL_NORM,SOLVER_VALUE,VALUE
    REAL(DP), POINTER :: RHS_DATA(:)
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: RHS_VECTOR,SOLVER_VECTOR
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: ROW_DOFS_MAPPING
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(SOLVER_MATRIX_TYPE), POINTER :: SOLVER_MATRIX
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_ITERATIVE_SOLVER)) THEN
      LINEAR_SOLVER=>LINEAR_ITERATIVE_SOLVER%LINEAR_SOLVER
      IF(ASSOCIATED(LINEAR_SOLVER)) THEN
        SOLVER=>LINEAR_SOLVER%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
          SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
          IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
            SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
            IF(ASSOCIATED(SOLVER_MATRICES)) THEN
              IF(SOLVER_MATRICES%NUMBER_OF_MATRICES==1) THEN
                SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(1)%PTR
                IF(ASSOCIATED(SOLVER_MATRIX)) THEN
                  RHS_VECTOR=>SOLVER_MATRICES%RHS_VECTOR
                  IF(ASSOCIATED(RHS_VECTOR)) THEN
                    SOLVER_VECTOR=>SOLVER_MATRICES%MATRICES(1)%PTR%SOLVER_VECTOR
                    IF(ASSOCIATED(SOLVER_VECTOR)) THEN
                      CALL DISTRIBUTED_MATRIX_STORAGE_TYPE_GET(SOLVER_MATRIX%MATRIX,STORAGE_TYPE,ERR,ERROR,*999)
                      IF(STORAGE_TYPE==DISTRIBUTED_MATRIX_DIAGONAL_STORAGE_TYPE) THEN
                        SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
                        IF(ASSOCIATED(SOLVER_MAPPING)) THEN
                          ROW_DOFS_MAPPING=>SOLVER_MAPPING%ROW_DOFS_MAPPING
                          IF(ASSOCIATED(ROW_DOFS_MAPPING)) THEN
                            CALL DISTRIBUTED_VECTOR_DATA_GET(RHS_VECTOR,RHS_DATA,ERR,ERROR,*999)
                            DO local_row=1,SOLVER_MAPPING%NUMBER_OF_ROWS
                              global_row=ROW_DOFS_MAPPING%LOCAL_TO_GLOBAL_MAP(local_row)
                              CALL DISTRIBUTED_MATRIX_VALUES_GET(SOLVER_MATRIX%MATRIX,local_row,global_row,VALUE,ERR,ERROR,*999)
                              IF(ABS(VALUE)>ZERO_TOLERANCE) THEN
                                SOLVER_VALUE=RHS_DATA(local_row)/VALUE
                                CALL DISTRIBUTED_VECTOR_VALUES_SET(SOLVER_VECTOR,local_row,SOLVER_VALUE,ERR,ERROR,*999)
                              ELSE
                                LOCAL_ERROR="The linear solver matrix has a zero pivot on row "// &
                                  & TRIM(NUMBER_TO_VSTRING(local_row,"*",ERR,ERROR))//"."
                                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                              ENDIF
                            ENDDO !matrix_idx
                            CALL DISTRIBUTED_VECTOR_DATA_RESTORE(RHS_VECTOR,RHS_DATA,ERR,ERROR,*999)
                          ELSE
                            CALL FLAG_ERROR("Solver mapping row dofs mapping is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Solver equations solver mapping is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        SELECT CASE(LINEAR_ITERATIVE_SOLVER%SOLVER_LIBRARY)
                        CASE(SOLVER_CMISS_LIBRARY)
                          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                        CASE(SOLVER_PETSC_LIBRARY)
                          IF(ASSOCIATED(RHS_VECTOR%PETSC)) THEN
                            IF(ASSOCIATED(SOLVER_VECTOR%PETSC)) THEN
                              SELECT CASE(LINEAR_ITERATIVE_SOLVER%SOLUTION_INITIALISE_TYPE)
                              CASE(SOLVER_SOLUTION_INITIALISE_ZERO)
                                !Zero the solution vector
                                CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(SOLVER_VECTOR,0.0_DP,ERR,ERROR,*999)
                                !Tell PETSc that the solution vector is zero
                                CALL PETSC_KSPSETINITIALGUESSNONZERO(LINEAR_ITERATIVE_SOLVER%KSP,.FALSE.,ERR,ERROR,*999)
                              CASE(SOLVER_SOLUTION_INITIALISE_CURRENT_FIELD)
                                !Make sure the solver vector contains the current dependent field values
                                CALL SOLVER_SOLUTION_UPDATE(SOLVER,ERR,ERROR,*999)
                                !Tell PETSc that the solution vector is nonzero
                                CALL PETSC_KSPSETINITIALGUESSNONZERO(LINEAR_ITERATIVE_SOLVER%KSP,.TRUE.,ERR,ERROR,*999)
                              CASE(SOLVER_SOLUTION_INITIALISE_NO_CHANGE)
                                !Do nothing
                              CASE DEFAULT
                                LOCAL_ERROR="The linear iterative solver solution initialise type of "// &
                                  & TRIM(NUMBER_TO_VSTRING(LINEAR_ITERATIVE_SOLVER%SOLUTION_INITIALISE_TYPE,"*",ERR,ERROR))// &
                                  & " is invalid."
                                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                              END SELECT
                              !Solver the linear system
#ifdef TAUPROF
                              CALL TAU_STATIC_PHASE_START("KSPSOLVE")
#endif
                              CALL PETSC_KSPSOLVE(LINEAR_ITERATIVE_SOLVER%KSP,RHS_VECTOR%PETSC%VECTOR,SOLVER_VECTOR%PETSC%VECTOR, &
                                & ERR,ERROR,*999)
#ifdef TAUPROF
                              CALL TAU_STATIC_PHASE_STOP("KSPSOLVE")
#endif
                              !Check for convergence
                              CALL PETSC_KSPGETCONVERGEDREASON(LINEAR_ITERATIVE_SOLVER%KSP,CONVERGED_REASON,ERR,ERROR,*999)
                              SELECT CASE(CONVERGED_REASON)
                              CASE(PETSC_KSP_DIVERGED_NULL)
                                CALL FLAG_WARNING("Linear iterative solver did not converge. PETSc diverged null.",ERR,ERROR,*999)
                              CASE(PETSC_KSP_DIVERGED_ITS)
                                CALL FLAG_WARNING("Linear iterative solver did not converge. PETSc diverged its.",ERR,ERROR,*999)
                              CASE(PETSC_KSP_DIVERGED_DTOL)
                                CALL FLAG_WARNING("Linear iterative solver did not converge. PETSc diverged dtol.",ERR,ERROR,*999)
                              CASE(PETSC_KSP_DIVERGED_BREAKDOWN)
                                CALL FLAG_WARNING("Linear iterative solver did not converge. PETSc diverged breakdown.", &
                                  & ERR,ERROR,*999)
                              CASE(PETSC_KSP_DIVERGED_BREAKDOWN_BICG)
                                CALL FLAG_WARNING("Linear iterative solver did not converge. PETSc diverged breakdown BiCG.", &
                                  & ERR,ERROR,*999)
                              CASE(PETSC_KSP_DIVERGED_NONSYMMETRIC)
                                CALL FLAG_WARNING("Linear iterative solver did not converge. PETSc diverged nonsymmetric.", &
                                  & ERR,ERROR,*999)
                              CASE(PETSC_KSP_DIVERGED_INDEFINITE_PC)
                                CALL FLAG_WARNING("Linear iterative solver did not converge. PETSc diverged indefinite PC.", &
                                  & ERR,ERROR,*999)
                              CASE(PETSC_KSP_DIVERGED_NAN)
                                CALL FLAG_WARNING("Linear iterative solver did not converge. PETSc diverged NaN.",ERR,ERROR,*999)
                              CASE(PETSC_KSP_DIVERGED_INDEFINITE_MAT)
                                CALL FLAG_WARNING("Linear iterative solver did not converge. PETSc diverged indefinite mat.", &
                                  & ERR,ERROR,*999)
                              END SELECT
                              IF(SOLVER%OUTPUT_TYPE>=SOLVER_SOLVER_OUTPUT) THEN
                                !Output solution characteristics
                                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Linear iterative solver parameters:",ERR,ERROR,*999)
                                CALL PETSC_KSPGETITERATIONNUMBER(LINEAR_ITERATIVE_SOLVER%KSP,NUMBER_ITERATIONS,ERR,ERROR,*999)
                                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Final number of iterations = ",NUMBER_ITERATIONS, &
                                  & ERR,ERROR,*999)
                                CALL PETSC_KSPGETRESIDUALNORM(LINEAR_ITERATIVE_SOLVER%KSP,RESIDUAL_NORM,ERR,ERROR,*999)
                                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Final residual norm = ",RESIDUAL_NORM, &
                                  & ERR,ERROR,*999)
                                SELECT CASE(CONVERGED_REASON)
                                CASE(PETSC_KSP_CONVERGED_RTOL)
                                  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged RTol",ERR,ERROR,*999)
                                CASE(PETSC_KSP_CONVERGED_ATOL)
                                  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged ATol",ERR,ERROR,*999)
                                CASE(PETSC_KSP_CONVERGED_ITS)
                                  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged its",ERR,ERROR,*999)
                                CASE(PETSC_KSP_CONVERGED_CG_NEG_CURVE)
                                  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged CG neg curve", &
                                    & ERR,ERROR,*999)
                                CASE(PETSC_KSP_CONVERGED_CG_CONSTRAINED)
                                  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged CG constrained", &
                                    & ERR,ERROR,*999)
                                CASE(PETSC_KSP_CONVERGED_STEP_LENGTH)
                                  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged step length", &
                                    & ERR,ERROR,*999)
                                CASE(PETSC_KSP_CONVERGED_HAPPY_BREAKDOWN)
                                  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged happy breakdown", &
                                    & ERR,ERROR,*999)
                                CASE(PETSC_KSP_CONVERGED_ITERATING)
                                  CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged iterating", &
                                    & ERR,ERROR,*999)
                                END SELECT
                              ENDIF
                            ELSE
                              CALL FLAG_ERROR("Solver vector PETSc vector is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("RHS vector petsc PETSc is not associated.",ERR,ERROR,*999)
                          ENDIF
                        CASE DEFAULT
                          LOCAL_ERROR="The solver library type of "// &
                            & TRIM(NUMBER_TO_VSTRING(LINEAR_ITERATIVE_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))//" is invalid."
                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                        END SELECT
                      ENDIF
                    ELSE
                      CALL FLAG_ERROR("Solver vector is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("RHS vector is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("Solver matrix is not associated.",ERR,ERROR,*999)
                ENDIF
              ELSE
                LOCAL_ERROR="The given number of solver matrices of "// &
                  & TRIM(NUMBER_TO_VSTRING(SOLVER_MATRICES%NUMBER_OF_MATRICES,"*",ERR,ERROR))// &
                  & " is invalid. There should only be one solver matrix for a linear iterative solver."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver solver matrices is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Linear solver solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Linear itreative solver linear solver is not associated.",ERR,ERROR,*999)
      ENDIF      
    ELSE
      CALL FLAG_ERROR("Linear iterative solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_SOLVE
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the type of iterative linear solver. \see OPENCMISS::CMISSSolverLinearIterativeTypeSet
  SUBROUTINE SOLVER_LINEAR_ITERATIVE_TYPE_SET(SOLVER,ITERATIVE_SOLVER_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the iterative linear solver type
    INTEGER(INTG), INTENT(IN) :: ITERATIVE_SOLVER_TYPE !<The type of iterative linear solver to set \see SOLVER_ROUTINES_IterativeLinearSolverTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_ITERATIVE_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_LINEAR_TYPE) THEN
          IF(ASSOCIATED(SOLVER%LINEAR_SOLVER)) THEN
            IF(SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE==SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE) THEN
              IF(ASSOCIATED(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER)) THEN
                IF(ITERATIVE_SOLVER_TYPE/=SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE) THEN
                  !Intialise the new solver type
                  SELECT CASE(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%SOLVER_LIBRARY)
                  CASE(SOLVER_PETSC_LIBRARY)
                    SELECT CASE(ITERATIVE_SOLVER_TYPE)
                    CASE(SOLVER_ITERATIVE_RICHARDSON)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE=SOLVER_ITERATIVE_RICHARDSON
                    CASE(SOLVER_ITERATIVE_CHEBYCHEV)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE=SOLVER_ITERATIVE_CHEBYCHEV
                    CASE(SOLVER_ITERATIVE_CONJUGATE_GRADIENT)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE=SOLVER_ITERATIVE_CONJUGATE_GRADIENT
                    CASE(SOLVER_ITERATIVE_BICONJUGATE_GRADIENT)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE=SOLVER_ITERATIVE_BICONJUGATE_GRADIENT
                    CASE(SOLVER_ITERATIVE_GMRES)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE=SOLVER_ITERATIVE_BiCGSTAB
                    CASE(SOLVER_ITERATIVE_BiCGSTAB)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE=SOLVER_ITERATIVE_BiCGSTAB
                    CASE(SOLVER_ITERATIVE_CONJGRAD_SQUARED)
                      SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%ITERATIVE_SOLVER_TYPE=SOLVER_ITERATIVE_CONJGRAD_SQUARED
                    CASE DEFAULT
                      LOCAL_ERROR="The iterative solver type of "//TRIM(NUMBER_TO_VSTRING(ITERATIVE_SOLVER_TYPE,"*",ERR,ERROR))// &
                        & " is invalid."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    END SELECT
                  CASE DEFAULT
                    LOCAL_ERROR="The solver library type of "// &
                      & TRIM(NUMBER_TO_VSTRING(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))// &
                      & " is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT                  
                ENDIF
              ELSE
                CALL FLAG_ERROR("The solver linear solver iterative solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The solver is not a linear iterative solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver linear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a linear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_ITERATIVE_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_ITERATIVE_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_ITERATIVE_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for a linear solver.
  SUBROUTINE SOLVER_LINEAR_LIBRARY_TYPE_GET(LINEAR_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER !<A pointer the linear solver to get the library type for.
     INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On exit, the type of library used for the linear solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER
    TYPE(LINEAR_ITERATIVE_SOLVER_TYPE), POINTER :: ITERATIVE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LINEAR_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_SOLVER)) THEN
      SELECT CASE(LINEAR_SOLVER%LINEAR_SOLVE_TYPE)
      CASE(SOLVER_LINEAR_DIRECT_SOLVE_TYPE)
        DIRECT_SOLVER=>LINEAR_SOLVER%DIRECT_SOLVER
        IF(ASSOCIATED(DIRECT_SOLVER)) THEN
          CALL SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_GET(DIRECT_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Linear solver direct solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE)
        ITERATIVE_SOLVER=>LINEAR_SOLVER%ITERATIVE_SOLVER
        IF(ASSOCIATED(ITERATIVE_SOLVER)) THEN
          CALL SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_GET(ITERATIVE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Linear solver iterative solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The linear solver type of "//TRIM(NUMBER_TO_VSTRING(LINEAR_SOLVER%LINEAR_SOLVE_TYPE,"*",ERR,ERROR))// &
          & " is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library to use for a linear solver.
  SUBROUTINE SOLVER_LINEAR_LIBRARY_TYPE_SET(LINEAR_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER !<A pointer the linear solver to get the library type for.
     INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library for the linear solver to set. \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER
    TYPE(LINEAR_ITERATIVE_SOLVER_TYPE), POINTER :: ITERATIVE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LINEAR_LIBRARY_TYPE_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(LINEAR_SOLVER)) THEN
      SELECT CASE(LINEAR_SOLVER%LINEAR_SOLVE_TYPE)
      CASE(SOLVER_LINEAR_DIRECT_SOLVE_TYPE)
        DIRECT_SOLVER=>LINEAR_SOLVER%DIRECT_SOLVER
        IF(ASSOCIATED(DIRECT_SOLVER)) THEN
          CALL SOLVER_LINEAR_DIRECT_LIBRARY_TYPE_SET(DIRECT_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Linear solver direct solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE)
        ITERATIVE_SOLVER=>LINEAR_SOLVER%ITERATIVE_SOLVER
        IF(ASSOCIATED(ITERATIVE_SOLVER)) THEN
          CALL SOLVER_LINEAR_ITERATIVE_LIBRARY_TYPE_SET(ITERATIVE_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Linear solver iterative solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The linear solver type of "//TRIM(NUMBER_TO_VSTRING(LINEAR_SOLVER%LINEAR_SOLVE_TYPE,"*",ERR,ERROR))// &
          & " is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_LIBRARY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_LIBRARY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for a linear solver matrices.
  SUBROUTINE SOLVER_LINEAR_MATRICES_LIBRARY_TYPE_GET(LINEAR_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER !<A pointer the linear solver to get the library type for.
     INTEGER(INTG), INTENT(OUT) :: MATRICES_LIBRARY_TYPE !<On exit, the type of library used for the linear solver matrices \see DISTRIBUTED_MATRIX_VECTOR_LibraryTypes,DISTRIBUTED_MATRIX_VECTOR
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(LINEAR_DIRECT_SOLVER_TYPE), POINTER :: DIRECT_SOLVER
    TYPE(LINEAR_ITERATIVE_SOLVER_TYPE), POINTER :: ITERATIVE_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LINEAR_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_SOLVER)) THEN
      SELECT CASE(LINEAR_SOLVER%LINEAR_SOLVE_TYPE)
      CASE(SOLVER_LINEAR_DIRECT_SOLVE_TYPE)
        DIRECT_SOLVER=>LINEAR_SOLVER%DIRECT_SOLVER
        IF(ASSOCIATED(DIRECT_SOLVER)) THEN
          CALL SOLVER_LINEAR_DIRECT_MATRICES_LIBRARY_TYPE_GET(DIRECT_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Linear solver direct solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE)
        ITERATIVE_SOLVER=>LINEAR_SOLVER%ITERATIVE_SOLVER
        IF(ASSOCIATED(ITERATIVE_SOLVER)) THEN
          CALL SOLVER_LINEAR_ITERATIVE_MATRICES_LIBRARY_TYPE_GET(ITERATIVE_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Linear solver iterative solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The linear solver type of "//TRIM(NUMBER_TO_VSTRING(LINEAR_SOLVER%LINEAR_SOLVE_TYPE,"*",ERR,ERROR))// &
          & " is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_MATRICES_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_MATRICES_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_MATRICES_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Solve a linear solver 
  SUBROUTINE SOLVER_LINEAR_SOLVE(LINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER !<A pointer to the linear solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
     TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_LINEAR_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(LINEAR_SOLVER)) THEN
      SOLVER=>LINEAR_SOLVER%SOLVER
      IF(ASSOCIATED(SOLVER)) THEN

#ifdef TAUPROF
        CALL TAU_STATIC_PHASE_START("Solver Matrix Assembly Phase")
#endif
        IF(.NOT.ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
          !Assemble the solver matrices
!!TODO: Work out what to assemble

          CALL SOLVER_MATRICES_STATIC_ASSEMBLE(SOLVER,SOLVER_MATRICES_LINEAR_ONLY,ERR,ERROR,*999)
        ENDIF

#ifdef TAUPROF
        CALL TAU_STATIC_PHASE_STOP("Solver Matrix Assembly Phase")

        CALL TAU_STATIC_PHASE_START("Solve Phase")
#endif
        SELECT CASE(LINEAR_SOLVER%LINEAR_SOLVE_TYPE)
        CASE(SOLVER_LINEAR_DIRECT_SOLVE_TYPE)
          CALL SOLVER_LINEAR_DIRECT_SOLVE(LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
        CASE(SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE)
          CALL SOLVER_LINEAR_ITERATIVE_SOLVE(LINEAR_SOLVER%ITERATIVE_SOLVER,ERR,ERROR,*999)
        CASE DEFAULT
          LOCAL_ERROR="The linear solver type of "//TRIM(NUMBER_TO_VSTRING(LINEAR_SOLVER%LINEAR_SOLVE_TYPE,"*",ERR,ERROR))// &
            & " is invalid."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
#ifdef TAUPROF
          CALL TAU_STATIC_PHASE_STOP("Solve Phase")
#endif
        IF(.NOT.ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
          !Update depenent field with solution
#ifdef TAUPROF
          CALL TAU_STATIC_PHASE_START("Field Update Phase")
#endif
          CALL SOLVER_VARIABLES_FIELD_UPDATE(SOLVER,ERR,ERROR,*999)
#ifdef TAUPROF
          CALL TAU_STATIC_PHASE_STOP("Field Update Phase")
#endif
        ENDIF
      ELSE
        CALL FLAG_ERROR("Linear solver solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Linear solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_LINEAR_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_LINEAR_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_SOLVE
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the type of linear solver. \see OPENCMISS::CMISSSolverLinearTypeSet
  SUBROUTINE SOLVER_LINEAR_TYPE_SET(SOLVER,LINEAR_SOLVE_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the linear solver type
    INTEGER(INTG), INTENT(IN) :: LINEAR_SOLVE_TYPE !<The type of linear solver to set \see SOLVER_ROUTINES_LinearSolverTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR
    
    CALL ENTERS("SOLVER_LINEAR_TYPE_SET",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*998)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_LINEAR_TYPE) THEN
          IF(ASSOCIATED(SOLVER%LINEAR_SOLVER)) THEN
            IF(LINEAR_SOLVE_TYPE/=SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE) THEN
              !Intialise the new solver type
              SELECT CASE(LINEAR_SOLVE_TYPE)
              CASE(SOLVER_LINEAR_DIRECT_SOLVE_TYPE)
                CALL SOLVER_LINEAR_DIRECT_INITIALISE(SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE)
                CALL SOLVER_LINEAR_ITERATIVE_INITIALISE(SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The linear solver type of "//TRIM(NUMBER_TO_VSTRING(LINEAR_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
              !Finalise the old solver type
              SELECT CASE(SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE)
              CASE(SOLVER_LINEAR_DIRECT_SOLVE_TYPE)
                CALL SOLVER_LINEAR_DIRECT_FINALISE(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE)
                CALL SOLVER_LINEAR_ITERATIVE_FINALISE(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER,ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The linear solver type of "// &
                  & TRIM(NUMBER_TO_VSTRING(SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
              SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE=LINEAR_SOLVE_TYPE
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver linear solver is not associated.",ERR,ERROR,*998)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a linear solver.",ERR,ERROR,*998)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
    
    CALL EXITS("SOLVER_LINEAR_TYPE_SET")
    RETURN
999 SELECT CASE(LINEAR_SOLVE_TYPE)
    CASE(SOLVER_LINEAR_DIRECT_SOLVE_TYPE)
      CALL SOLVER_LINEAR_DIRECT_FINALISE(SOLVER%LINEAR_SOLVER%DIRECT_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    CASE(SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE)
      CALL SOLVER_LINEAR_ITERATIVE_FINALISE(SOLVER%LINEAR_SOLVER%ITERATIVE_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    END SELECT
998 CALL ERRORS("SOLVER_LINEAR_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_LINEAR_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_LINEAR_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Assembles the solver matrices and rhs from the dynamic equations.
  SUBROUTINE SOLVER_MATRICES_DYNAMIC_ASSEMBLE(SOLVER,SELECTION_TYPE,ERR,ERROR,*)
    
    !Argument variable
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the solver
    INTEGER(INTG), INTENT(IN) :: SELECTION_TYPE !<The type of matrix selection \see SOLVER_MATRICES_ROUTINES_SelectMatricesTypes,SOLVER_MATRICES_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DYNAMIC_VARIABLE_TYPE,equations_matrix_idx,equations_row_number,equations_set_idx,LINEAR_VARIABLE_TYPE, &
      & rhs_boundary_condition,rhs_global_dof,rhs_variable_dof,rhs_variable_type,solver_row_idx,solver_row_number, &
      & solver_matrix_idx, residual_variable_type,residual_variable_dof,variable_boundary_condition,variable_type, &
      & variable_idx,variable_global_dof,variable_dof,equations_row_number2,equations_matrix_number,DEPENDENT_VARIABLE_TYPE, &
      & equations_column_number,dirichlet_row,dirichlet_idx
    REAL(SP) :: SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),USER_ELAPSED,USER_TIME1(1),USER_TIME2(1)
    REAL(DP) :: DAMPING_MATRIX_COEFFICIENT,DELTA_T,DYNAMIC_VALUE,FIRST_UPDATE_FACTOR,RESIDUAL_VALUE, &
      & LINEAR_VALUE,LINEAR_VALUE_SUM,MASS_MATRIX_COEFFICIENT,RHS_VALUE,row_coupling_coefficient,PREVIOUS_RESIDUAL_VALUE, &
      & SECOND_UPDATE_FACTOR,SOURCE_VALUE,STIFFNESS_MATRIX_COEFFICIENT,VALUE,JACOBIAN_MATRIX_COEFFICIENT,UPDATE_VALUE, &
      & MATRIX_VALUE
    REAL(DP), POINTER :: RHS_PARAMETERS(:), BOUNDARY_CONDITION_VECTOR(:)
    TYPE(BOUNDARY_CONDITIONS_TYPE), POINTER :: BOUNDARY_CONDITIONS
    TYPE(BOUNDARY_CONDITIONS_VARIABLE_TYPE), POINTER :: RHS_BOUNDARY_CONDITIONS,DEPENDENT_BOUNDARY_CONDITIONS
    TYPE(DISTRIBUTED_MATRIX_TYPE), POINTER :: PREVIOUS_SOLVER_DISTRIBUTED_MATRIX,SOLVER_DISTRIBUTED_MATRIX
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: DEPENDENT_VECTOR,DYNAMIC_TEMP_VECTOR,EQUATIONS_RHS_VECTOR,DISTRIBUTED_SOURCE_VECTOR, &
      & LINEAR_TEMP_VECTOR,PREDICTED_MEAN_ACCELERATION_VECTOR,PREDICTED_MEAN_DISPLACEMENT_VECTOR,PREDICTED_MEAN_VELOCITY_VECTOR, &
      & SOLVER_RHS_VECTOR, SOLVER_RESIDUAL_VECTOR,RESIDUAL_VECTOR,INCREMENTAL_VECTOR
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: RESIDUAL_DOMAIN_MAPPING,RHS_DOMAIN_MAPPING,VARIABLE_DOMAIN_MAPPING
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MAPPING_DYNAMIC_TYPE), POINTER :: DYNAMIC_MAPPING
    TYPE(EQUATIONS_MAPPING_LINEAR_TYPE), POINTER :: LINEAR_MAPPING
    TYPE(EQUATIONS_MAPPING_NONLINEAR_TYPE), POINTER :: NONLINEAR_MAPPING
    TYPE(EQUATIONS_MAPPING_RHS_TYPE), POINTER :: RHS_MAPPING
    TYPE(EQUATIONS_MAPPING_SOURCE_TYPE), POINTER :: SOURCE_MAPPING
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_DYNAMIC_TYPE), POINTER :: DYNAMIC_MATRICES
    TYPE(EQUATIONS_MATRICES_LINEAR_TYPE), POINTER :: LINEAR_MATRICES
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: NONLINEAR_MATRICES
    TYPE(EQUATIONS_MATRICES_RHS_TYPE), POINTER :: RHS_VECTOR
    TYPE(EQUATIONS_MATRICES_SOURCE_TYPE), POINTER :: SOURCE_VECTOR
    TYPE(EQUATIONS_MATRIX_TYPE), POINTER :: DAMPING_MATRIX,LINEAR_MATRIX,MASS_MATRIX,STIFFNESS_MATRIX,EQUATIONS_MATRIX
    TYPE(EQUATIONS_JACOBIAN_TYPE), POINTER :: JACOBIAN_MATRIX
    TYPE(JACOBIAN_TO_SOLVER_MAP_TYPE), POINTER :: JACOBIAN_TO_SOLVER_MAP
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: DYNAMIC_VARIABLE,LINEAR_VARIABLE,RHS_VARIABLE,RESIDUAL_VARIABLE
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: DEPENDENT_VARIABLE
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(SOLVER_MATRIX_TYPE), POINTER :: SOLVER_MATRIX
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    TYPE(BOUNDARY_CONDITIONS_SPARSITY_INDICES_TYPE), POINTER :: SPARSITY_INDICES

    REAL(DP), POINTER :: CHECK_DATA(:),PREVIOUS_RESIDUAL_PARAMETERS(:),CHECK_DATA2(:)
    !STABILITY_TEST under investigation
    LOGICAL :: STABILITY_TEST
    !.FALSE. guarantees weighting as described in OpenCMISS notes
    !.TRUE. weights mean predicted field rather than the whole NL contribution
    !-> to be removed later
    STABILITY_TEST=.FALSE.
   
    CALL ENTERS("SOLVER_MATRICES_DYNAMIC_ASSEMBLE",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      NULLIFY(DYNAMIC_SOLVER)
      NULLIFY(SOLVER_EQUATIONS)
      NULLIFY(SOLVER_MAPPING)
      NULLIFY(SOLVER_MATRICES)
      
      !Determine which dynamic solver needs to be used
      IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
        DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
      ELSE IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN 
        DYNAMIC_SOLVER=>SOLVER%LINKING_SOLVER%DYNAMIC_SOLVER
      ELSE
        CALL FLAG_ERROR("Dynamic solver solve type is not associated.",ERR,ERROR,*999)
      END IF
      IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
        IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
          DELTA_T=DYNAMIC_SOLVER%TIME_INCREMENT
          SELECT CASE(DYNAMIC_SOLVER%DEGREE)
          CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
            STIFFNESS_MATRIX_COEFFICIENT=1.0_DP*DYNAMIC_SOLVER%THETA(1)*DELTA_T
            DAMPING_MATRIX_COEFFICIENT=1.0_DP            
            MASS_MATRIX_COEFFICIENT=0.0_DP
            JACOBIAN_MATRIX_COEFFICIENT=STIFFNESS_MATRIX_COEFFICIENT
          CASE(SOLVER_DYNAMIC_SECOND_DEGREE)
            STIFFNESS_MATRIX_COEFFICIENT=1.0_DP*(DYNAMIC_SOLVER%THETA(2)*DELTA_T*DELTA_T)/2.0_DP
            DAMPING_MATRIX_COEFFICIENT=1.0_DP*DYNAMIC_SOLVER%THETA(1)*DELTA_T
            MASS_MATRIX_COEFFICIENT=1.0_DP
            JACOBIAN_MATRIX_COEFFICIENT=STIFFNESS_MATRIX_COEFFICIENT
            FIRST_UPDATE_FACTOR=DELTA_T
          CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
            STIFFNESS_MATRIX_COEFFICIENT=1.0_DP*(DYNAMIC_SOLVER%THETA(3)*DELTA_T*DELTA_T*DELTA_T)/6.0_DP
            DAMPING_MATRIX_COEFFICIENT=1.0_DP*(DYNAMIC_SOLVER%THETA(2)*DELTA_T*DELTA_T)/2.0_DP
            MASS_MATRIX_COEFFICIENT=1.0_DP*DYNAMIC_SOLVER%THETA(1)*DELTA_T
            JACOBIAN_MATRIX_COEFFICIENT=STIFFNESS_MATRIX_COEFFICIENT
            FIRST_UPDATE_FACTOR=DELTA_T
            SECOND_UPDATE_FACTOR=DELTA_T*DELTA_T/2.0_DP
          CASE DEFAULT
            LOCAL_ERROR="The dynamic solver degree of "//TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))// &
              & " is invalid."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ENDIF
        SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
        IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
          SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
          IF(ASSOCIATED(SOLVER_MAPPING)) THEN
            SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
            IF(ASSOCIATED(SOLVER_MATRICES)) THEN
              !Assemble the solver matrices
              NULLIFY(PREVIOUS_SOLVER_DISTRIBUTED_MATRIX)
              NULLIFY(SOLVER_MATRIX)
              NULLIFY(SOLVER_DISTRIBUTED_MATRIX)
              NULLIFY(EQUATIONS)
              NULLIFY(EQUATIONS_MATRICES)
              NULLIFY(DYNAMIC_MATRICES)
              NULLIFY(EQUATIONS_MAPPING)
              NULLIFY(DYNAMIC_MAPPING)
              NULLIFY(STIFFNESS_MATRIX)
              NULLIFY(DAMPING_MATRIX)
              NULLIFY(MASS_MATRIX)

              IF(SELECTION_TYPE==SOLVER_MATRICES_ALL.OR. &
                & SELECTION_TYPE==SOLVER_MATRICES_LINEAR_ONLY.OR. &
                & SELECTION_TYPE==SOLVER_MATRICES_NONLINEAR_ONLY.OR. &
                & SELECTION_TYPE==SOLVER_MATRICES_JACOBIAN_ONLY) THEN
                IF(DYNAMIC_SOLVER%SOLVER_INITIALISED.OR.(.NOT.DYNAMIC_SOLVER%SOLVER_INITIALISED.AND. &
                  & ((DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_FIRST_ORDER.AND.DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_FIRST_DEGREE).OR. &
                  & (DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_SECOND_ORDER.AND.DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_SECOND_DEGREE)))) &
                  & THEN
                  !Assemble solver matrices
                  IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                    CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
                    CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
                  ENDIF
!               DO solver_matrix_idx=1,SOLVER_MAPPING%NUMBER_OF_SOLVER_MATRICES
!                 SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(solver_matrix_idx)%PTR
!                 END DO

                  solver_matrix_idx=1
                  IF(SOLVER_MAPPING%NUMBER_OF_SOLVER_MATRICES==solver_matrix_idx) THEN
                    SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(1)%PTR
                    IF(ASSOCIATED(SOLVER_MATRIX)) THEN
                      IF(SOLVER_MATRIX%UPDATE_MATRIX) THEN      
                        SOLVER_DISTRIBUTED_MATRIX=>SOLVER_MATRIX%MATRIX
                        IF(ASSOCIATED(SOLVER_DISTRIBUTED_MATRIX)) THEN
                          !Initialise matrix to zero
                          CALL DISTRIBUTED_MATRIX_ALL_VALUES_SET(SOLVER_DISTRIBUTED_MATRIX,0.0_DP,ERR,ERROR,*999)
                          !Loop over the equations sets
                          DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                            EQUATIONS=>SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)%EQUATIONS
                            IF(ASSOCIATED(EQUATIONS)) THEN
                              EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                              IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                                DYNAMIC_MAPPING=>EQUATIONS_MAPPING%DYNAMIC_MAPPING
                                IF(ASSOCIATED(DYNAMIC_MAPPING)) THEN
                                  EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                                  IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                                    DYNAMIC_MATRICES=>EQUATIONS_MATRICES%DYNAMIC_MATRICES
                                    IF(ASSOCIATED(DYNAMIC_MATRICES)) THEN
                                      IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN

                                        IF(DYNAMIC_MAPPING%STIFFNESS_MATRIX_NUMBER/=0) THEN
                                          STIFFNESS_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%STIFFNESS_MATRIX_NUMBER)%PTR
                                          IF(ASSOCIATED(STIFFNESS_MATRIX)) THEN
                                            CALL SOLVER_MATRIX_EQUATIONS_MATRIX_ADD(SOLVER_MATRIX,equations_set_idx, &
                                              & STIFFNESS_MATRIX_COEFFICIENT,STIFFNESS_MATRIX,ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Dynamic stiffness matrix is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ENDIF

                                        IF(DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER/=0) THEN
                                          DAMPING_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER)%PTR
                                          IF(ASSOCIATED(DAMPING_MATRIX)) THEN
                                            CALL SOLVER_MATRIX_EQUATIONS_MATRIX_ADD(SOLVER_MATRIX,equations_set_idx, &
                                              & DAMPING_MATRIX_COEFFICIENT,DAMPING_MATRIX,ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Dynamic damping matrix is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ENDIF

                                        IF(DYNAMIC_MAPPING%MASS_MATRIX_NUMBER/=0) THEN
                                          MASS_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%MASS_MATRIX_NUMBER)%PTR
                                          IF(ASSOCIATED(MASS_MATRIX)) THEN
                                            CALL SOLVER_MATRIX_EQUATIONS_MATRIX_ADD(SOLVER_MATRIX,equations_set_idx, &
                                              & MASS_MATRIX_COEFFICIENT,MASS_MATRIX,ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Dynamic mass matrix is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ENDIF

                                      ELSE
                                        IF(DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_SECOND_ORDER.AND. &
                                          & DYNAMIC_SOLVER%DEGREE==SOLVER_DYNAMIC_THIRD_DEGREE) THEN
                                          IF(DYNAMIC_MAPPING%MASS_MATRIX_NUMBER/=0) THEN
                                            MASS_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%MASS_MATRIX_NUMBER)%PTR
                                            IF(ASSOCIATED(MASS_MATRIX)) THEN
                                              CALL SOLVER_MATRIX_EQUATIONS_MATRIX_ADD(SOLVER_MATRIX,equations_set_idx, &
                                                & -1.0_DP,MASS_MATRIX,ERR,ERROR,*999)
                                            ELSE
                                              CALL FLAG_ERROR("Dynamic stiffness matrix is not associated.",ERR,ERROR,*999)
                                            ENDIF
                                          ELSE
                                            CALL FLAG_ERROR("Can not perform initial solve with no mass matrix.",ERR,ERROR,*999)
                                          ENDIF
                                        ELSE
                                          IF(DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER/=0) THEN
                                            DAMPING_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER)%PTR
                                            IF(ASSOCIATED(DAMPING_MATRIX)) THEN
                                              CALL SOLVER_MATRIX_EQUATIONS_MATRIX_ADD(SOLVER_MATRIX,equations_set_idx, &
                                                & -1.0_DP,DAMPING_MATRIX,ERR,ERROR,*999)
                                            ELSE
                                              CALL FLAG_ERROR("Dynamic damping matrix is not associated.",ERR,ERROR,*999)
                                            ENDIF
                                          ELSE
                                            CALL FLAG_ERROR("Can not perform initial solve with no damping matrix.",ERR,ERROR,*999)
                                          ENDIF
                                        ENDIF
                                      ENDIF
                                    ELSE
                                      CALL FLAG_ERROR("Equations matrices dynamic matrices is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ELSE
                                    CALL FLAG_ERROR("Equations equations matrices is not associated.",ERR,ERROR,*999)
                                  ENDIF
                                ELSE
                                  CALL FLAG_ERROR("Equations mapping dynamic mapping is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                CALL FLAG_ERROR("Equations equations mapping is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              LOCAL_ERROR="Solver mapping equations is not associated for equations set number "// &
                                & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."                          
                              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                            ENDIF
                            NULLIFY(JACOBIAN_TO_SOLVER_MAP)
                            NULLIFY(JACOBIAN_MATRIX)
                            IF(SELECTION_TYPE==SOLVER_MATRICES_ALL.OR. &
                              & SELECTION_TYPE==SOLVER_MATRICES_NONLINEAR_ONLY.OR. &
                              & SELECTION_TYPE==SOLVER_MATRICES_JACOBIAN_ONLY) THEN

                              !Now set the values from the equations Jacobian
                              JACOBIAN_TO_SOLVER_MAP=>SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%JACOBIAN_TO_SOLVER_MATRIX_MAP
                              IF(ASSOCIATED(JACOBIAN_TO_SOLVER_MAP)) THEN
                                JACOBIAN_MATRIX=>JACOBIAN_TO_SOLVER_MAP%JACOBIAN_MATRIX
                                IF(ASSOCIATED(JACOBIAN_MATRIX)) THEN
                                  CALL SOLVER_MATRIX_JACOBIAN_MATRIX_ADD(SOLVER_MATRIX,equations_set_idx, & 
                                    & JACOBIAN_MATRIX_COEFFICIENT,JACOBIAN_MATRIX,ERR,ERROR,*999)
                                ELSE
                                  CALL FLAG_ERROR("Jacobian matrix is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ENDIF
                            ENDIF
                          ENDDO !equations_set_idx

                          !Update the solver matrix values
                          CALL DISTRIBUTED_MATRIX_UPDATE_START(SOLVER_DISTRIBUTED_MATRIX,ERR,ERROR,*999)

                          IF(ASSOCIATED(PREVIOUS_SOLVER_DISTRIBUTED_MATRIX)) THEN
                            CALL DISTRIBUTED_MATRIX_UPDATE_FINISH(PREVIOUS_SOLVER_DISTRIBUTED_MATRIX,ERR,ERROR,*999)
                          ENDIF
                          PREVIOUS_SOLVER_DISTRIBUTED_MATRIX=>SOLVER_DISTRIBUTED_MATRIX
                        ELSE
                          CALL FLAG_ERROR("Solver matrix distributed matrix is not associated.",ERR,ERROR,*999)
                        ENDIF

                        IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
                          IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) SOLVER_MATRIX%UPDATE_MATRIX=.FALSE.
                        ELSE IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN 
                          IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) SOLVER_MATRIX%UPDATE_MATRIX=.TRUE.
                        ELSE
                          CALL FLAG_ERROR("Dynamic solver solve type is not associated.",ERR,ERROR,*999)
                        END IF

                      ENDIF !Update matrix
                    ELSE
                      CALL FLAG_ERROR("Solver matrix is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("Invalid number of solver matrices.",ERR,ERROR,*999)
                  ENDIF
                  IF(ASSOCIATED(PREVIOUS_SOLVER_DISTRIBUTED_MATRIX)) THEN
                    CALL DISTRIBUTED_MATRIX_UPDATE_FINISH(PREVIOUS_SOLVER_DISTRIBUTED_MATRIX,ERR,ERROR,*999)
                  ENDIF
                  IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                    CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
                    CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
                    USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
                    SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
                    CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for solver matrices assembly = ",USER_ELAPSED, &
                      & ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total System time for solver matrices assembly = ", &
                      & SYSTEM_ELAPSED,ERR,ERROR,*999)
                    CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
                  ENDIF
                ENDIF
              ENDIF

              NULLIFY(SOLVER_RHS_VECTOR)
              IF(SELECTION_TYPE==SOLVER_MATRICES_ALL.OR. &
                & SELECTION_TYPE==SOLVER_MATRICES_LINEAR_ONLY.OR. &
                & SELECTION_TYPE==SOLVER_MATRICES_NONLINEAR_ONLY.OR. &
                & SELECTION_TYPE==SOLVER_MATRICES_RHS_RESIDUAL_ONLY.OR. &
                & SELECTION_TYPE==SOLVER_MATRICES_RHS_ONLY) THEN
                IF(DYNAMIC_SOLVER%SOLVER_INITIALISED.OR.(.NOT.DYNAMIC_SOLVER%SOLVER_INITIALISED.AND. &
                  & ((DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_FIRST_ORDER.AND.DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_FIRST_DEGREE).OR. &
                  & (DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_SECOND_ORDER.AND.DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_SECOND_DEGREE)))) &
                  & THEN
                  !Assemble rhs vector
                  IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                    CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
                    CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
                  ENDIF
                  IF(SOLVER_MATRICES%UPDATE_RHS_VECTOR) THEN

                    SOLVER_RHS_VECTOR=>SOLVER_MATRICES%RHS_VECTOR
                    IF(ASSOCIATED(SOLVER_RHS_VECTOR)) THEN
                      !Initialise the RHS to zero
                      CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(SOLVER_RHS_VECTOR,0.0_DP,ERR,ERROR,*999)          
                      !Get the solver variables data                  
                      NULLIFY(CHECK_DATA)
                      CALL DISTRIBUTED_VECTOR_DATA_GET(SOLVER_RHS_VECTOR,CHECK_DATA,ERR,ERROR,*999)             
                      !Loop over the equations sets
                      DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                        EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                        IF(ASSOCIATED(EQUATIONS_SET)) THEN
                          NULLIFY(DEPENDENT_FIELD) 
                          DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                          EQUATIONS=>EQUATIONS_SET%EQUATIONS
                          IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                            IF(ASSOCIATED(EQUATIONS)) THEN
                              EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                              IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                                EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                                IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN

                                  DYNAMIC_MAPPING=>EQUATIONS_MAPPING%DYNAMIC_MAPPING
                                  IF(ASSOCIATED(DYNAMIC_MAPPING)) THEN
                                    DYNAMIC_VARIABLE_TYPE=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPE
                                    !Calculate the dynamic contributions
                                    DYNAMIC_VARIABLE=>DYNAMIC_MAPPING%DYNAMIC_VARIABLE
                                    IF(ASSOCIATED(DYNAMIC_VARIABLE)) THEN
                                      DYNAMIC_MATRICES=>EQUATIONS_MATRICES%DYNAMIC_MATRICES
                                      IF(ASSOCIATED(DYNAMIC_MATRICES)) THEN
                                        DYNAMIC_TEMP_VECTOR=>DYNAMIC_MATRICES%TEMP_VECTOR
                                        !Initialise the dynamic temporary vector to zero
                                        CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(DYNAMIC_TEMP_VECTOR,0.0_DP,ERR,ERROR,*999)
                                        IF(DYNAMIC_MAPPING%STIFFNESS_MATRIX_NUMBER/=0) THEN
                                          STIFFNESS_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%STIFFNESS_MATRIX_NUMBER)%PTR
                                          IF(ASSOCIATED(STIFFNESS_MATRIX)) THEN
                                            NULLIFY(PREDICTED_MEAN_DISPLACEMENT_VECTOR)
                                            CALL FIELD_PARAMETER_SET_VECTOR_GET(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                              & FIELD_MEAN_PREDICTED_DISPLACEMENT_SET_TYPE,PREDICTED_MEAN_DISPLACEMENT_VECTOR, &
                                              & ERR,ERROR,*999)
                                            CALL DISTRIBUTED_MATRIX_BY_VECTOR_ADD(DISTRIBUTED_MATRIX_VECTOR_NO_GHOSTS_TYPE, &
                                              & -1.0_DP,STIFFNESS_MATRIX%MATRIX, &
!                                              & -DYNAMIC_SOLVER%THETA(1),STIFFNESS_MATRIX%MATRIX, &
                                              & PREDICTED_MEAN_DISPLACEMENT_VECTOR,DYNAMIC_TEMP_VECTOR,ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Dynamic stiffness matrix is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ENDIF

                                        IF(DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER/=0.AND. &
                                          & DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_FIRST_DEGREE) THEN
                                          DAMPING_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER)%PTR
                                          IF(ASSOCIATED(DAMPING_MATRIX)) THEN
                                            NULLIFY(PREDICTED_MEAN_VELOCITY_VECTOR)
                                            CALL FIELD_PARAMETER_SET_VECTOR_GET(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                              & FIELD_MEAN_PREDICTED_VELOCITY_SET_TYPE,PREDICTED_MEAN_VELOCITY_VECTOR, &
                                              & ERR,ERROR,*999)
                                            CALL DISTRIBUTED_MATRIX_BY_VECTOR_ADD(DISTRIBUTED_MATRIX_VECTOR_NO_GHOSTS_TYPE,-1.0_DP,&
                                              & DAMPING_MATRIX%MATRIX,PREDICTED_MEAN_VELOCITY_VECTOR,DYNAMIC_TEMP_VECTOR, &
                                              & ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Dynamic damping matrix is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ENDIF
                                        IF(DYNAMIC_MAPPING%MASS_MATRIX_NUMBER/=0.AND. &
                                          & DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_SECOND_DEGREE) THEN
                                          MASS_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%MASS_MATRIX_NUMBER)%PTR
                                          IF(ASSOCIATED(MASS_MATRIX)) THEN
                                            NULLIFY(PREDICTED_MEAN_ACCELERATION_VECTOR)
                                            CALL FIELD_PARAMETER_SET_VECTOR_GET(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                              & FIELD_MEAN_PREDICTED_ACCELERATION_SET_TYPE,PREDICTED_MEAN_ACCELERATION_VECTOR, &
                                              & ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Dynamic mass matrix is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ENDIF
                                      ELSE
                                        CALL FLAG_ERROR("Equations matrices dynamic matrices is not associated.",ERR,ERROR,*999)
                                      ENDIF
                                    ELSE
                                      CALL FLAG_ERROR("Dynamic variable is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ELSE
                                    CALL FLAG_ERROR("Equations mapping dynamic mapping is not associated.",ERR,ERROR,*999)
                                  ENDIF

                                  !Calculate the contributions from any linear matrices 
                                  LINEAR_MAPPING=>EQUATIONS_MAPPING%LINEAR_MAPPING
                                  IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                                    LINEAR_MATRICES=>EQUATIONS_MATRICES%LINEAR_MATRICES
                                    IF(ASSOCIATED(LINEAR_MATRICES)) THEN
                                      DO equations_matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                                        LINEAR_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_idx)%PTR
                                        IF(ASSOCIATED(LINEAR_MATRIX)) THEN
                                          LINEAR_VARIABLE_TYPE=LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)% &
                                            & VARIABLE_TYPE
                                          LINEAR_VARIABLE=>LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)% &
                                            & VARIABLE
                                          IF(ASSOCIATED(LINEAR_VARIABLE)) THEN
                                            LINEAR_TEMP_VECTOR=>LINEAR_MATRIX%TEMP_VECTOR
                                            !Initialise the linear temporary vector to zero
                                            CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(LINEAR_TEMP_VECTOR,0.0_DP,ERR,ERROR,*999)
                                            NULLIFY(DEPENDENT_VECTOR)
                                            CALL FIELD_PARAMETER_SET_VECTOR_GET(DEPENDENT_FIELD,LINEAR_VARIABLE_TYPE, &
                                              & FIELD_VALUES_SET_TYPE,DEPENDENT_VECTOR,ERR,ERROR,*999)
                                            CALL DISTRIBUTED_MATRIX_BY_VECTOR_ADD(DISTRIBUTED_MATRIX_VECTOR_NO_GHOSTS_TYPE,1.0_DP, &
                                              & LINEAR_MATRIX%MATRIX,DEPENDENT_VECTOR,LINEAR_TEMP_VECTOR,ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Linear variable is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ELSE
                                          LOCAL_ERROR="Linear matrix is not associated for linear matrix number "// &
                                            & TRIM(NUMBER_TO_VSTRING(equations_matrix_idx,"*",ERR,ERROR))//"."
                                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                                        ENDIF
                                      ENDDO !equations_matrix_idx
                                    ELSE
                                      CALL FLAG_ERROR("Equations matrices linear matrices is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ENDIF
                                  SOURCE_MAPPING=>EQUATIONS_MAPPING%SOURCE_MAPPING
                                  IF(ASSOCIATED(SOURCE_MAPPING)) THEN
                                    SOURCE_VECTOR=>EQUATIONS_MATRICES%SOURCE_VECTOR
                                    IF(ASSOCIATED(SOURCE_VECTOR)) THEN
                                      DISTRIBUTED_SOURCE_VECTOR=>SOURCE_VECTOR%VECTOR
                                    ELSE
                                      CALL FLAG_ERROR("Source vector vector is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ENDIF
                                  RHS_MAPPING=>EQUATIONS_MAPPING%RHS_MAPPING
                                  IF(ASSOCIATED(RHS_MAPPING)) THEN
                                    RHS_VARIABLE_TYPE=RHS_MAPPING%RHS_VARIABLE_TYPE
                                    CALL FIELD_PARAMETER_SET_DATA_GET(DEPENDENT_FIELD,RHS_VARIABLE_TYPE, &
                                      & FIELD_VALUES_SET_TYPE,RHS_PARAMETERS,ERR,ERROR,*999)
                                    RHS_VECTOR=>EQUATIONS_MATRICES%RHS_VECTOR
                                    IF(ASSOCIATED(RHS_VECTOR)) THEN
                                      BOUNDARY_CONDITIONS=>EQUATIONS_SET%BOUNDARY_CONDITIONS
                                      IF(ASSOCIATED(BOUNDARY_CONDITIONS)) THEN
  !!TODO: what if the equations set doesn't have a RHS vector???
                                        rhs_variable_type=RHS_MAPPING%RHS_VARIABLE_TYPE
                                        RHS_VARIABLE=>RHS_MAPPING%RHS_VARIABLE
                                        RHS_DOMAIN_MAPPING=>RHS_VARIABLE%DOMAIN_MAPPING
                                        EQUATIONS_RHS_VECTOR=>RHS_VECTOR%VECTOR
                                        RHS_BOUNDARY_CONDITIONS=>BOUNDARY_CONDITIONS%BOUNDARY_CONDITIONS_VARIABLE_TYPE_MAP( &
                                          & rhs_variable_type)%PTR
                                        IF(ASSOCIATED(RHS_BOUNDARY_CONDITIONS)) THEN

! ! !-----------------------------------------------------------------------------------------------------------------------
! ! !Routine to assemble integrated flux values - section below to be moved to a stand-alone routine
! ! 
! !                                         NUMBER_OF_NEUMANN_ROWS=0
! !                                         DO equations_row_number=1,EQUATIONS_MAPPING%TOTAL_NUMBER_OF_ROWS
! ! 
! !                                           rhs_variable_dof=RHS_MAPPING%EQUATIONS_ROW_TO_RHS_DOF_MAP(equations_row_number)
! !                                           rhs_global_dof=RHS_DOMAIN_MAPPING%LOCAL_TO_GLOBAL_MAP(rhs_variable_dof)
! !                                           rhs_boundary_condition=RHS_BOUNDARY_CONDITIONS%GLOBAL_BOUNDARY_CONDITIONS(rhs_global_dof)
! !                                           IF(rhs_boundary_condition==BOUNDARY_CONDITION_FIXED) THEN
! !                                             NUMBER_OF_NEUMANN_ROWS=NUMBER_OF_NEUMANN_ROWS+1
! !                                           ENDIF
! !                                         ENDDO !equations_row_number
! ! 
! !                                         !Calculate the Neumann integrated flux boundary conditions
! !                                         IF(NUMBER_OF_NEUMANN_ROWS>0) THEN
! !                                           IF(ASSOCIATED(LINEAR_MAPPING).AND..NOT.ASSOCIATED(NONLINEAR_MAPPING)) THEN
! ! 
! !                                             CALL BOUNDARY_CONDITIONS_INTEGRATED_CALCULATE(BOUNDARY_CONDITIONS, &
! !                                               & RHS_VARIABLE_TYPE,ERR,ERROR,*999)
! ! 
! !                                             !Loop over the rows in the equations set
! !                                             DO equations_row_number=1,EQUATIONS_MAPPING%TOTAL_NUMBER_OF_ROWS
! !                                               IF(ASSOCIATED(LINEAR_MAPPING).AND..NOT.ASSOCIATED(NONLINEAR_MAPPING)) THEN
! ! 
! !                                                 !Loop over the dependent variables associated with this equations set row
! !                                                 DO variable_idx=1,LINEAR_MAPPING%NUMBER_OF_LINEAR_MATRIX_VARIABLES
! ! 
! !                                                   variable_dof=LINEAR_MAPPING%EQUATIONS_ROW_TO_VARIABLE_DOF_MAPS( &
! !                                                     & equations_row_number,variable_idx)
! ! 
! !                                                   !Locate calculated value at dof
! !                                                   INTEGRATED_VALUE=0.0_DP
! !                                                   DO j=1,RHS_BOUNDARY_CONDITIONS%NEUMANN_BOUNDARY_CONDITIONS &
! !                                                                                       & %INTEGRATED_VALUES_VECTOR_SIZE
! ! 
! !                                                     IF((INTEGRATED_VALUE==0.0_DP).AND. &
! !                                                       & (RHS_BOUNDARY_CONDITIONS%NEUMANN_BOUNDARY_CONDITIONS% &
! !                                                       & INTEGRATED_VALUES_VECTOR_MAPPING(j)==variable_dof)) THEN
! ! 
! !                                                       INTEGRATED_VALUE=RHS_BOUNDARY_CONDITIONS &
! !                                                                        & %NEUMANN_BOUNDARY_CONDITIONS%INTEGRATED_VALUES_VECTOR(j)
! ! 
! !                                                       CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD, &
! !                                                               & rhs_variable_type,FIELD_VALUES_SET_TYPE, &
! !                                                               & variable_dof,INTEGRATED_VALUE,ERR,ERROR,*999)
! ! 
! !                                                     ENDIF
! !                                                   ENDDO !j
! ! 
! !                                                 ENDDO !variable_idx
! !                                               ENDIF
! !                                             ENDDO !equations_row_number
! ! 
! !                                             DEALLOCATE(RHS_BOUNDARY_CONDITIONS%NEUMANN_BOUNDARY_CONDITIONS% &
! !                                                     & INTEGRATED_VALUES_VECTOR_MAPPING)
! !                                             DEALLOCATE(RHS_BOUNDARY_CONDITIONS%NEUMANN_BOUNDARY_CONDITIONS% &
! !                                                     & INTEGRATED_VALUES_VECTOR)
! ! 
! !                                           ENDIF
! !                                         ENDIF
! ! 
! ! !-------------------------------------------------------------------------------------------------------------------------

                                          !Loop over the rows in the equations set
                                          DO equations_row_number=1,EQUATIONS_MAPPING%TOTAL_NUMBER_OF_ROWS
                                            !Get the dynamic contribution to the the RHS values
                                            CALL DISTRIBUTED_VECTOR_VALUES_GET(DYNAMIC_TEMP_VECTOR,equations_row_number, &
                                              & DYNAMIC_VALUE,ERR,ERROR,*999)
                                            !Get the linear matrices contribution to the RHS values if there are any
                                            IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                                              LINEAR_VALUE_SUM=0.0_DP
                                              DO equations_matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                                                LINEAR_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_idx)%PTR
                                                LINEAR_TEMP_VECTOR=>LINEAR_MATRIX%TEMP_VECTOR
                                                CALL DISTRIBUTED_VECTOR_VALUES_GET(LINEAR_TEMP_VECTOR,equations_row_number, &
                                                  & LINEAR_VALUE,ERR,ERROR,*999)
                                                LINEAR_VALUE_SUM=LINEAR_VALUE_SUM+LINEAR_VALUE
                                              ENDDO !equations_matrix_idx
                                              DYNAMIC_VALUE=DYNAMIC_VALUE+LINEAR_VALUE_SUM
                                            ENDIF
                                            !Get the source vector contribute to the RHS values if there are any
                                            IF(ASSOCIATED(SOURCE_MAPPING)) THEN
                                              !Add in equations source values
                                              CALL DISTRIBUTED_VECTOR_VALUES_GET(DISTRIBUTED_SOURCE_VECTOR,equations_row_number, &
                                                & SOURCE_VALUE,ERR,ERROR,*999)
                                              DYNAMIC_VALUE=DYNAMIC_VALUE+SOURCE_VALUE
                                            ENDIF
                                            !Get the nonlinear vector contribute to the RHS values if nonlinear solve
                                            IF(.NOT.STABILITY_TEST) THEN 
                                              IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN 
                                                NONLINEAR_MAPPING=>EQUATIONS_MAPPING%NONLINEAR_MAPPING
                                                  IF(ASSOCIATED(NONLINEAR_MAPPING)) THEN
                                                   NULLIFY(PREVIOUS_RESIDUAL_PARAMETERS)
                                                   CALL FIELD_PARAMETER_SET_DATA_GET(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                                     & FIELD_PREVIOUS_RESIDUAL_SET_TYPE,PREVIOUS_RESIDUAL_PARAMETERS,ERR,ERROR, &
                                                     & *999)  
                                                   residual_variable_dof=NONLINEAR_MAPPING% & 
                                                     & EQUATIONS_ROW_TO_RESIDUAL_DOF_MAP(equations_row_number)
                                                    PREVIOUS_RESIDUAL_VALUE=-1.0_DP*PREVIOUS_RESIDUAL_PARAMETERS & 
                                                      & (residual_variable_dof)
                                                    DYNAMIC_VALUE=DYNAMIC_VALUE+PREVIOUS_RESIDUAL_VALUE*(1.0_DP-DYNAMIC_SOLVER% & 
                                                      & THETA(1))
                                                  ENDIF
                                              END IF
                                            END IF
                                            !Loop over the solver rows associated with this equations set row
                                            DO solver_row_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                              & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%NUMBER_OF_SOLVER_ROWS
                                              solver_row_number=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                                & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%SOLVER_ROWS( &
                                                & solver_row_idx)
                                              row_coupling_coefficient=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP( &
                                                & equations_set_idx)%EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
                                                & COUPLING_COEFFICIENTS(solver_row_idx)
                                               VALUE=DYNAMIC_VALUE*row_coupling_coefficient
                                               CALL DISTRIBUTED_VECTOR_VALUES_ADD(SOLVER_RHS_VECTOR,solver_row_number,VALUE, &
                                                & ERR,ERROR,*999)
                                            ENDDO !solver_row_idx
                                          ENDDO !equations_row_number
                                         CALL FIELD_PARAMETER_SET_DATA_GET(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                            FIELD_INCREMENTAL_VALUES_SET_TYPE,BOUNDARY_CONDITION_VECTOR,ERR,ERROR,*999)

                                          DO equations_row_number=1,EQUATIONS_MAPPING%TOTAL_NUMBER_OF_ROWS
                                            !Get the dynamic contribution to the the RHS values
                                            rhs_variable_dof=RHS_MAPPING%EQUATIONS_ROW_TO_RHS_DOF_MAP(equations_row_number)
                                            rhs_global_dof=RHS_DOMAIN_MAPPING%LOCAL_TO_GLOBAL_MAP(rhs_variable_dof)
                                            rhs_boundary_condition=RHS_BOUNDARY_CONDITIONS% & 
                                              & GLOBAL_BOUNDARY_CONDITIONS(rhs_global_dof)
                                            !Apply boundary conditions
                                            SELECT CASE(rhs_boundary_condition)
                                            CASE(BOUNDARY_CONDITION_NOT_FIXED,BOUNDARY_CONDITION_FREE_WALL)
                                              !Get the equations RHS values
                                              CALL DISTRIBUTED_VECTOR_VALUES_GET(EQUATIONS_RHS_VECTOR,equations_row_number, &
                                                & RHS_VALUE,ERR,ERROR,*999)
                                              !Loop over the solver rows associated with this equations set row
                                              DO solver_row_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                                & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%NUMBER_OF_SOLVER_ROWS
                                                solver_row_number=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                                  & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%SOLVER_ROWS( &
                                                  & solver_row_idx)
                                                row_coupling_coefficient=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP( &
                                                  & equations_set_idx)%EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
                                                  & COUPLING_COEFFICIENTS(solver_row_idx)
                                                VALUE=RHS_VALUE*row_coupling_coefficient
                                                CALL DISTRIBUTED_VECTOR_VALUES_ADD(SOLVER_RHS_VECTOR,solver_row_number,VALUE, &
                                                  & ERR,ERROR,*999)
                                              ENDDO !solver_row_idx
                                              !Note: the Dirichlet boundary conditions are implicitly included by doing a matrix
                                              !vector product above with the dynamic stiffness matrix and the mean predicited
                                              !displacement vector
                                              !
                                              !This is only true for nonlinear cases and linear cases with fixed values at the boundaries
                                              !
                                              !For changing linear boundary conditions the following needs to be added 
                                              !             
                                              IF(DYNAMIC_SOLVER%UPDATE_BC)THEN
                                                !Set Dirichlet boundary conditions
                                                IF(SOLVER%SOLVE_TYPE==SOLVER_DYNAMIC_TYPE) THEN
                                                !for linear case only |
!                                                 IF(ASSOCIATED(LINEAR_MAPPING).AND..NOT.ASSOCIATED(NONLINEAR_MAPPING)) THEN
                                                  !Loop over the dependent variables associated with this equations set row
!                                                   DO variable_idx=1,DYNAMIC_MAPPING%NUMBER_OF_LINEAR_MATRIX_VARIABLES
                                                    variable_idx=1
!                                                     variable_type=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPES(variable_idx)
                                                    variable_type=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPE
                                                    DEPENDENT_VARIABLE=>DYNAMIC_MAPPING%VAR_TO_EQUATIONS_MATRICES_MAPS( &
                                                      & variable_type)%VARIABLE
                                                    DEPENDENT_VARIABLE_TYPE=DEPENDENT_VARIABLE%VARIABLE_TYPE
                                                    VARIABLE_DOMAIN_MAPPING=>DEPENDENT_VARIABLE%DOMAIN_MAPPING
                                                    DEPENDENT_BOUNDARY_CONDITIONS=>BOUNDARY_CONDITIONS% &
                                                      & BOUNDARY_CONDITIONS_VARIABLE_TYPE_MAP(DEPENDENT_VARIABLE_TYPE)%PTR
                                                    variable_dof=DYNAMIC_MAPPING%EQUATIONS_ROW_TO_VARIABLE_DOF_MAPS( &
                                                      & equations_row_number)
                                                    variable_global_dof=VARIABLE_DOMAIN_MAPPING%LOCAL_TO_GLOBAL_MAP(variable_dof)
                                                    variable_boundary_condition=DEPENDENT_BOUNDARY_CONDITIONS% &
                                                      & GLOBAL_BOUNDARY_CONDITIONS(variable_global_dof)

                                                    IF(variable_boundary_condition==BOUNDARY_CONDITION_FIXED.OR. & 
                                                      & variable_boundary_condition==BOUNDARY_CONDITION_FIXED_INLET.OR. &
                                                      & variable_boundary_condition==BOUNDARY_CONDITION_FIXED_OUTLET.OR. &  
                                                      & variable_boundary_condition==BOUNDARY_CONDITION_FIXED_WALL.OR. & 
                                                      & variable_boundary_condition==BOUNDARY_CONDITION_MOVED_WALL) THEN

                                                      UPDATE_VALUE=BOUNDARY_CONDITION_VECTOR(variable_dof)

                                                      IF(ABS(UPDATE_VALUE)>=ZERO_TOLERANCE) THEN
                                                        DO equations_matrix_idx=1,DYNAMIC_MAPPING%VAR_TO_EQUATIONS_MATRICES_MAPS( &
                                                          & variable_type)%NUMBER_OF_EQUATIONS_MATRICES
                                                          equations_matrix_number=DYNAMIC_MAPPING%VAR_TO_EQUATIONS_MATRICES_MAPS( &
                                                            & variable_type)%EQUATIONS_MATRIX_NUMBERS(equations_matrix_idx)
                                                          IF(equations_matrix_number==DYNAMIC_MAPPING%STIFFNESS_MATRIX_NUMBER) & 
                                                            & THEN 
                                                             UPDATE_VALUE=UPDATE_VALUE*STIFFNESS_MATRIX_COEFFICIENT
                                                          ENDIF
                                                          IF(equations_matrix_number==DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER) &
                                                            & THEN 
                                                             UPDATE_VALUE=UPDATE_VALUE*DAMPING_MATRIX_COEFFICIENT
                                                          ENDIF
                                                          IF(equations_matrix_number==DYNAMIC_MAPPING%MASS_MATRIX_NUMBER) &
                                                            & THEN 
                                                             UPDATE_VALUE=UPDATE_VALUE*MASS_MATRIX_COEFFICIENT
                                                          ENDIF
                                                          EQUATIONS_MATRIX=>DYNAMIC_MATRICES% &
                                                            & MATRICES(equations_matrix_number)%PTR
                                                          equations_column_number=DYNAMIC_MAPPING% &
                                                            & VAR_TO_EQUATIONS_MATRICES_MAPS(variable_type)% &
                                                            & DOF_TO_COLUMNS_MAPS(equations_matrix_idx)% &
                                                            & COLUMN_DOF(variable_dof)
                                                          IF(ASSOCIATED(DEPENDENT_BOUNDARY_CONDITIONS% &
                                                            & DIRICHLET_BOUNDARY_CONDITIONS)) THEN
                                                            IF(DEPENDENT_BOUNDARY_CONDITIONS% &
                                                              & NUMBER_OF_DIRICHLET_CONDITIONS>0) THEN
                                                              DO dirichlet_idx=1,DEPENDENT_BOUNDARY_CONDITIONS% &
                                                                & NUMBER_OF_DIRICHLET_CONDITIONS
                                                                IF(DEPENDENT_BOUNDARY_CONDITIONS% &
                                                                  & DIRICHLET_BOUNDARY_CONDITIONS% &
                                                                  & DIRICHLET_DOF_INDICES(dirichlet_idx)== &
                                                                  & equations_column_number) EXIT
                                                              ENDDO
                                                              SPARSITY_INDICES=>DEPENDENT_BOUNDARY_CONDITIONS% &
                                                                & DIRICHLET_BOUNDARY_CONDITIONS%DYNAMIC_SPARSITY_INDICES( &
                                                                & equations_matrix_idx)%PTR
                                                              IF(ASSOCIATED(SPARSITY_INDICES)) THEN
                                                                DO equations_row_number2=SPARSITY_INDICES% &                               
                                                                  & SPARSE_COLUMN_INDICES(dirichlet_idx), &
                                                                  & SPARSITY_INDICES%SPARSE_COLUMN_INDICES( &
                                                                  & dirichlet_idx+1)-1
                                                                  dirichlet_row=SPARSITY_INDICES%SPARSE_ROW_INDICES( &
                                                                    & equations_row_number2)
                                                                  CALL DISTRIBUTED_MATRIX_VALUES_GET(EQUATIONS_MATRIX% &
                                                                    & MATRIX,dirichlet_row,equations_column_number, &
                                                                    & MATRIX_VALUE,ERR,ERROR,*999)
                                                                  IF(ABS(MATRIX_VALUE)>=ZERO_TOLERANCE) THEN
                                                                    DO solver_row_idx=1,SOLVER_MAPPING% &
                                                                      & EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% & 
                                                                      & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS( &
                                                                      & dirichlet_row)%NUMBER_OF_SOLVER_ROWS
                                                                      solver_row_number=SOLVER_MAPPING% &
                                                                        & EQUATIONS_SET_TO_SOLVER_MAP( &
                                                                        & equations_set_idx)% &
                                                                        & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS( &
                                                                        & dirichlet_row)%SOLVER_ROWS(solver_row_idx)
                                                                      row_coupling_coefficient=SOLVER_MAPPING% &
                                                                        & EQUATIONS_SET_TO_SOLVER_MAP( &
                                                                        & equations_set_idx)% &
                                                                        & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS( &
                                                                        & dirichlet_row)%COUPLING_COEFFICIENTS( &
                                                                        & solver_row_idx)
                                                                      VALUE=-1.0_DP*MATRIX_VALUE*UPDATE_VALUE* &
                                                                        & row_coupling_coefficient
                                                                      CALL DISTRIBUTED_VECTOR_VALUES_ADD( &
                                                                        & SOLVER_RHS_VECTOR, &
                                                                        & solver_row_number,VALUE,ERR,ERROR,*999)
                                                                    ENDDO !solver_row_idx
                                                                  ENDIF
                                                                ENDDO !equations_row_number2
                                                              ELSE
                                                                CALL FLAG_ERROR("Sparsity indices are not associated.", &
                                                                  & ERR,ERROR,*999)
                                                              ENDIF
                                                            ENDIF
                                                          ELSE
                                                            CALL FLAG_ERROR("Dirichlet boundary conditions is &
                                                              & not associated.",ERR,ERROR,*999)
                                                          ENDIF
                                                        ENDDO !matrix_idx
                                                      ENDIF
                                                    ENDIF
!                                                   ENDDO !variable_idx
                                                ENDIF
                                              ENDIF

                                            CASE(BOUNDARY_CONDITION_FIXED)
                                              !Set Neumann boundary conditions
                                              !Loop over the solver rows associated with this equations set row
                                              DO solver_row_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                                & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%NUMBER_OF_SOLVER_ROWS
                                                solver_row_number=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                                  & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%SOLVER_ROWS( &
                                                  & solver_row_idx)
                                                row_coupling_coefficient=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP( &
                                                  & equations_set_idx)%EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
                                                  & COUPLING_COEFFICIENTS(solver_row_idx)
                                                VALUE=RHS_PARAMETERS(rhs_variable_dof)*row_coupling_coefficient
                                                CALL DISTRIBUTED_VECTOR_VALUES_ADD(SOLVER_RHS_VECTOR,solver_row_number,VALUE, &
                                                  & ERR,ERROR,*999)
                                              ENDDO !solver_row_idx
                                            CASE(BOUNDARY_CONDITION_MIXED)
                                              !Set Robin or is it Cauchy??? boundary conditions
                                              CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                                            CASE DEFAULT
                                              LOCAL_ERROR="The RHS boundary condition of "// &
                                                & TRIM(NUMBER_TO_VSTRING(rhs_boundary_condition,"*",ERR,ERROR))// &
                                                & " for RHS variable dof number "// &
                                                & TRIM(NUMBER_TO_VSTRING(rhs_variable_dof,"*",ERR,ERROR))//" is invalid."
                                              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                                            END SELECT
                                          ENDDO !equations_row_number
                                        ELSE
                                          CALL FLAG_ERROR("RHS boundary conditions variable is not associated.",ERR,ERROR,*999)
                                        ENDIF
                                      ELSE
                                        CALL FLAG_ERROR("Equations set boundary conditions is not associated.",ERR,ERROR,*999)
                                      ENDIF
                                    ELSE
                                      CALL FLAG_ERROR("Equations matrices RHS vector is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                    CALL FIELD_PARAMETER_SET_DATA_RESTORE(DEPENDENT_FIELD,RHS_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                                      & RHS_PARAMETERS,ERR,ERROR,*999)
                                  ELSE
                                    CALL FLAG_ERROR("Equations mapping RHS mapping is not associated.",ERR,ERROR,*999)
                                  ENDIF
                                ELSE
                                  CALL FLAG_ERROR("Equations equations mapping is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                CALL FLAG_ERROR("Equations equations matrices is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              CALL FLAG_ERROR("Equations set equations is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("Equations set dependent field is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ENDDO !equations_set_idx
                      !Start the update the solver RHS vector values
                      CALL DISTRIBUTED_VECTOR_UPDATE_START(SOLVER_RHS_VECTOR,ERR,ERROR,*999)

                      NULLIFY(CHECK_DATA)
                      CALL DISTRIBUTED_VECTOR_DATA_GET(SOLVER_RHS_VECTOR,CHECK_DATA,ERR,ERROR,*999)

                    ELSE
                      CALL FLAG_ERROR("The solver RHS vector is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ENDIF
                  IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                    CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
                    CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
                    USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
                    SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
                    CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for solver RHS assembly = ",USER_ELAPSED, &
                      & ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total System time for solver RHS assembly = ",SYSTEM_ELAPSED, &
                      & ERR,ERROR,*999)
                    CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
                  ENDIF
                ENDIF
              END IF

              NULLIFY(SOLVER_RESIDUAL_VECTOR)
              IF(SELECTION_TYPE==SOLVER_MATRICES_ALL.OR. &
                & SELECTION_TYPE==SOLVER_MATRICES_NONLINEAR_ONLY.OR. &
                & SELECTION_TYPE==SOLVER_MATRICES_RESIDUAL_ONLY.OR. &
                & SELECTION_TYPE==SOLVER_MATRICES_RHS_RESIDUAL_ONLY) THEN
                IF(DYNAMIC_SOLVER%SOLVER_INITIALISED.OR.(.NOT.DYNAMIC_SOLVER%SOLVER_INITIALISED.AND. &
                  & ((DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_FIRST_ORDER.AND.DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_FIRST_DEGREE).OR. & 
                  & (DYNAMIC_SOLVER%ORDER==SOLVER_DYNAMIC_SECOND_ORDER.AND.DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_SECOND_DEGREE)))) &
                  & THEN
                  !Assemble residual vector
                  IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                    CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
                    CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
                  ENDIF
                  IF(SOLVER_MATRICES%UPDATE_RESIDUAL) THEN       
                    SOLVER_RESIDUAL_VECTOR=>SOLVER_MATRICES%RESIDUAL
                    IF(ASSOCIATED(SOLVER_RESIDUAL_VECTOR)) THEN
                      !Initialise the residual to zero              
                      CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(SOLVER_RESIDUAL_VECTOR,0.0_DP,ERR,ERROR,*999)       
                      !Get the solver variables data                  
                      NULLIFY(CHECK_DATA)
                      CALL DISTRIBUTED_VECTOR_DATA_GET(SOLVER_RESIDUAL_VECTOR,CHECK_DATA,ERR,ERROR,*999)             
                      !Loop over the equations sets
                      DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                        EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                        IF(ASSOCIATED(EQUATIONS_SET)) THEN
                          DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                          IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                            EQUATIONS=>EQUATIONS_SET%EQUATIONS
                            IF(ASSOCIATED(EQUATIONS)) THEN
                              EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                              IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                                EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                                IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                                  DYNAMIC_MAPPING=>EQUATIONS_MAPPING%DYNAMIC_MAPPING
                                  IF(ASSOCIATED(DYNAMIC_MAPPING)) THEN
                                    DYNAMIC_VARIABLE_TYPE=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPE
                                    !Calculate the dynamic contributions
                                    DYNAMIC_VARIABLE=>DYNAMIC_MAPPING%DYNAMIC_VARIABLE
                                    IF(ASSOCIATED(DYNAMIC_VARIABLE)) THEN
                                      DYNAMIC_MATRICES=>EQUATIONS_MATRICES%DYNAMIC_MATRICES
                                      IF(ASSOCIATED(DYNAMIC_MATRICES)) THEN
                                        DYNAMIC_TEMP_VECTOR=>DYNAMIC_MATRICES%TEMP_VECTOR
                                        !Initialise the dynamic temporary vector to zero
                                        CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(DYNAMIC_TEMP_VECTOR,0.0_DP,ERR,ERROR,*999)
                                        NULLIFY(INCREMENTAL_VECTOR)
                                        !Define the pointer to the INCREMENTAL_VECTOR
                                        CALL FIELD_PARAMETER_SET_VECTOR_GET(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                          & FIELD_INCREMENTAL_VALUES_SET_TYPE,INCREMENTAL_VECTOR,ERR,ERROR,*999)
                                        IF(DYNAMIC_MAPPING%STIFFNESS_MATRIX_NUMBER/=0) THEN
                                          STIFFNESS_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%STIFFNESS_MATRIX_NUMBER)%PTR
                                          IF(ASSOCIATED(STIFFNESS_MATRIX)) THEN
                                            CALL DISTRIBUTED_MATRIX_BY_VECTOR_ADD(DISTRIBUTED_MATRIX_VECTOR_NO_GHOSTS_TYPE, & 
                                              & STIFFNESS_MATRIX_COEFFICIENT,STIFFNESS_MATRIX%MATRIX,INCREMENTAL_VECTOR, & 
                                              & DYNAMIC_TEMP_VECTOR,ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Dynamic stiffness matrix is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ENDIF
                                        IF(DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER/=0.AND. &
                                          & DYNAMIC_SOLVER%DEGREE>=SOLVER_DYNAMIC_FIRST_DEGREE) THEN
                                          DAMPING_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%DAMPING_MATRIX_NUMBER)%PTR
                                          IF(ASSOCIATED(DAMPING_MATRIX)) THEN
                                            CALL DISTRIBUTED_MATRIX_BY_VECTOR_ADD(DISTRIBUTED_MATRIX_VECTOR_NO_GHOSTS_TYPE, &
                                              & DAMPING_MATRIX_COEFFICIENT,DAMPING_MATRIX%MATRIX,INCREMENTAL_VECTOR, & 
                                              & DYNAMIC_TEMP_VECTOR,ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Dynamic damping matrix is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ENDIF
                                        IF(DYNAMIC_MAPPING%MASS_MATRIX_NUMBER/=0.AND. &
                                          & DYNAMIC_SOLVER%DEGREE>=SOLVER_DYNAMIC_SECOND_DEGREE) THEN
                                          MASS_MATRIX=>DYNAMIC_MATRICES%MATRICES(DYNAMIC_MAPPING%MASS_MATRIX_NUMBER)%PTR
                                          IF(ASSOCIATED(MASS_MATRIX)) THEN
                                            CALL DISTRIBUTED_MATRIX_BY_VECTOR_ADD(DISTRIBUTED_MATRIX_VECTOR_NO_GHOSTS_TYPE, &
                                              & MASS_MATRIX_COEFFICIENT,MASS_MATRIX%MATRIX,INCREMENTAL_VECTOR, & 
                                              & DYNAMIC_TEMP_VECTOR,ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Dynamic mass matrix is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ENDIF
                                      ELSE
                                        CALL FLAG_ERROR("Dynamic variable is not associated.",ERR,ERROR,*999)
                                      ENDIF
                                    ELSE
                                      CALL FLAG_ERROR("Equations matrices dynamic matrices is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ENDIF
                                  !Calculate the contributions from any linear matrices 
                                  LINEAR_MAPPING=>EQUATIONS_MAPPING%LINEAR_MAPPING
                                  IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                                    LINEAR_MATRICES=>EQUATIONS_MATRICES%LINEAR_MATRICES
                                    IF(ASSOCIATED(LINEAR_MATRICES)) THEN
                                      DO equations_matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                                        LINEAR_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_idx)%PTR
                                        IF(ASSOCIATED(LINEAR_MATRIX)) THEN
                                          LINEAR_VARIABLE_TYPE=LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)% &
                                            & VARIABLE_TYPE
                                          LINEAR_VARIABLE=>LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)% &
                                            & VARIABLE
                                          IF(ASSOCIATED(LINEAR_VARIABLE)) THEN
                                            LINEAR_TEMP_VECTOR=>LINEAR_MATRIX%TEMP_VECTOR
                                            !Initialise the linear temporary vector to zero
                                            CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(LINEAR_TEMP_VECTOR,0.0_DP,ERR,ERROR,*999)
                                            NULLIFY(DEPENDENT_VECTOR)
                                            CALL FIELD_PARAMETER_SET_VECTOR_GET(DEPENDENT_FIELD,LINEAR_VARIABLE_TYPE, &
                                              & FIELD_VALUES_SET_TYPE,DEPENDENT_VECTOR,ERR,ERROR,*999)
                                            CALL DISTRIBUTED_MATRIX_BY_VECTOR_ADD(DISTRIBUTED_MATRIX_VECTOR_NO_GHOSTS_TYPE, &
                                              & 1.0_DP,LINEAR_MATRIX%MATRIX,DEPENDENT_VECTOR,LINEAR_TEMP_VECTOR,ERR,ERROR,*999)
                                          ELSE
                                            CALL FLAG_ERROR("Linear variable is not associated.",ERR,ERROR,*999)
                                          ENDIF
                                        ELSE
                                          LOCAL_ERROR="Linear matrix is not associated for linear matrix number "// &
                                            & TRIM(NUMBER_TO_VSTRING(equations_matrix_idx,"*",ERR,ERROR))//"."
                                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                                        ENDIF
                                      ENDDO !equations_matrix_idx
                                    ELSE
                                      CALL FLAG_ERROR("Equations matrices linear matrices is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ENDIF
                                  !Calculate the solver residual
                                  NONLINEAR_MAPPING=>EQUATIONS_MAPPING%NONLINEAR_MAPPING
                                  IF(ASSOCIATED(NONLINEAR_MAPPING)) THEN
                                    NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
                                    IF(ASSOCIATED(NONLINEAR_MATRICES)) THEN
                                      residual_variable_type=NONLINEAR_MAPPING%RESIDUAL_VARIABLE_TYPE
                                      RESIDUAL_VARIABLE=>NONLINEAR_MAPPING%RESIDUAL_VARIABLE
                                      RESIDUAL_DOMAIN_MAPPING=>RESIDUAL_VARIABLE%DOMAIN_MAPPING
                                      RESIDUAL_VECTOR=>NONLINEAR_MATRICES%RESIDUAL
                                      !Loop over the rows in the equations set
                                      DO equations_row_number=1,EQUATIONS_MAPPING%NUMBER_OF_ROWS
                                        IF(SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                          & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
                                          & NUMBER_OF_SOLVER_ROWS>0) THEN
                                          !Get the equations residual contribution
                                          CALL DISTRIBUTED_VECTOR_VALUES_GET(RESIDUAL_VECTOR,equations_row_number, &
                                            & RESIDUAL_VALUE,ERR,ERROR,*999)
                                          IF(STABILITY_TEST) THEN
                                            RESIDUAL_VALUE=RESIDUAL_VALUE
                                          ELSE
                                            RESIDUAL_VALUE=RESIDUAL_VALUE*DYNAMIC_SOLVER%THETA(1)
                                          ENDIF
                                          !Get the linear matrices contribution to the RHS values if there are any
                                          IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                                            LINEAR_VALUE_SUM=0.0_DP
                                            DO equations_matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                                              LINEAR_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_idx)%PTR
                                              LINEAR_TEMP_VECTOR=>LINEAR_MATRIX%TEMP_VECTOR
                                              CALL DISTRIBUTED_VECTOR_VALUES_GET(LINEAR_TEMP_VECTOR,equations_row_number, &
                                                & LINEAR_VALUE,ERR,ERROR,*999)
                                              LINEAR_VALUE_SUM=LINEAR_VALUE_SUM+LINEAR_VALUE
                                            ENDDO !equations_matrix_idx
                                            RESIDUAL_VALUE=RESIDUAL_VALUE+LINEAR_VALUE_SUM
                                          ENDIF
                                          IF(ASSOCIATED(DYNAMIC_MAPPING)) THEN
                                            !Get the dynamic contribution to the residual values
                                            CALL DISTRIBUTED_VECTOR_VALUES_GET(DYNAMIC_TEMP_VECTOR,equations_row_number, &
                                              & DYNAMIC_VALUE,ERR,ERROR,*999)
                                               RESIDUAL_VALUE=RESIDUAL_VALUE+DYNAMIC_VALUE
                                          ENDIF
                                          !Loop over the solver rows associated with this equations set residual row
                                          DO solver_row_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                            & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%NUMBER_OF_SOLVER_ROWS
                                            solver_row_number=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                              & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%SOLVER_ROWS( &
                                              & solver_row_idx)
                                            row_coupling_coefficient=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP( &
                                              & equations_set_idx)%EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
                                              & COUPLING_COEFFICIENTS(solver_row_idx)
                                            VALUE=RESIDUAL_VALUE*row_coupling_coefficient
!                                             VALUE=VALUE*DYNAMIC_SOLVER%THETA(1)
                                            !Add in nonlinear residual values                                    
                                            CALL DISTRIBUTED_VECTOR_VALUES_ADD(SOLVER_RESIDUAL_VECTOR,solver_row_number,VALUE, &
                                              & ERR,ERROR,*999)
                                          ENDDO !solver_row_idx
                                        ENDIF
                                      ENDDO !equations_row_number
                                    ELSE
                                      CALL FLAG_ERROR("Equations matrices nonlinear matrices is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ELSE
                                    CALL FLAG_ERROR("Equations mapping nonlinear mapping is not associated.",ERR,ERROR,*999)
                                  ENDIF
                                ELSE
                                  CALL FLAG_ERROR("Equations equations mapping is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                CALL FLAG_ERROR("Equations equations matrices is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              CALL FLAG_ERROR("Equations set equations is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("Equations set dependent field is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ENDDO !equations_set_idx
                      !Start the update the solver residual vector values
                      CALL DISTRIBUTED_VECTOR_UPDATE_START(SOLVER_RESIDUAL_VECTOR,ERR,ERROR,*999)

                      NULLIFY(CHECK_DATA2)
                      CALL DISTRIBUTED_VECTOR_DATA_GET(SOLVER_RESIDUAL_VECTOR,CHECK_DATA2,ERR,ERROR,*999)

                    ELSE
                      CALL FLAG_ERROR("The solver residual vector is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ENDIF
                  IF(ASSOCIATED(SOLVER_RESIDUAL_VECTOR)) THEN
                    CALL DISTRIBUTED_VECTOR_UPDATE_FINISH(SOLVER_RESIDUAL_VECTOR,ERR,ERROR,*999)
                  ENDIF
                  IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                    CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
                    CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
                    USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
                    SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
                    CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for solver residual assembly = ", & 
                      & USER_ELAPSED,ERR,ERROR,*999)
                    CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total System time for solver residual assembly = ", & 
                      & SYSTEM_ELAPSED,ERR,ERROR,*999)
                    CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
                  ENDIF
                ENDIF
              ENDIF

              IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
                !Set the first part of the next time step. Note that we do not have to add in the previous time value as it is
                !already there from when we copied the values to the previous time step.
                !Loop over the equations sets
                IF(DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_FIRST_DEGREE) THEN
                  DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                    EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                    IF(ASSOCIATED(EQUATIONS_SET)) THEN
                      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                        EQUATIONS=>EQUATIONS_SET%EQUATIONS
                        IF(ASSOCIATED(EQUATIONS)) THEN
                          EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                          IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                            DYNAMIC_MAPPING=>EQUATIONS_MAPPING%DYNAMIC_MAPPING
                            IF(ASSOCIATED(DYNAMIC_MAPPING)) THEN
                              DYNAMIC_VARIABLE_TYPE=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPE
                              SELECT CASE(DYNAMIC_SOLVER%DEGREE)
                              CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
                                !Do nothing. Increment will be added after the solve.
                              CASE(SOLVER_DYNAMIC_SECOND_DEGREE)
                                CALL FIELD_PARAMETER_SETS_ADD(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIRST_UPDATE_FACTOR, &
                                  & FIELD_PREVIOUS_VELOCITY_SET_TYPE,FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
                              CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
                                CALL FIELD_PARAMETER_SETS_ADD(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,(/FIRST_UPDATE_FACTOR, &
                                  & SECOND_UPDATE_FACTOR/),(/FIELD_PREVIOUS_VELOCITY_SET_TYPE,FIELD_PREVIOUS_VALUES_SET_TYPE/), &
                                  & FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
                                CALL FIELD_PARAMETER_SETS_ADD(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIRST_UPDATE_FACTOR, &
                                  & FIELD_PREVIOUS_ACCELERATION_SET_TYPE,FIELD_VELOCITY_VALUES_SET_TYPE,ERR,ERROR,*999)
                              CASE DEFAULT
                                LOCAL_ERROR="The dynamic solver degree of "// &
                                  & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))//" is invalid."
                                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)                        
                              END SELECT
                            ELSE
                              LOCAL_ERROR="Equations mapping dynamic mapping is not associated for equations set index number "// &
                                & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            LOCAL_ERROR="Equations equations mapping is not associated for equations set index number "// &
                              & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          LOCAL_ERROR="Equations set equations is not associated for equations set index number "// &
                            & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        LOCAL_ERROR="Equations set dependent field is not associated for equations set index number "// &
                          & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      LOCAL_ERROR="Equations set is not associated for equations set index number "// &
                        & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ENDDO !equations_set_idx
                ENDIF
              ENDIF
              IF(ASSOCIATED(SOLVER_RHS_VECTOR)) THEN
                CALL DISTRIBUTED_VECTOR_UPDATE_FINISH(SOLVER_RHS_VECTOR,ERR,ERROR,*999)
              ENDIF
              !If required output the solver matrices          
              IF(SOLVER%OUTPUT_TYPE>=SOLVER_MATRIX_OUTPUT) THEN
                CALL SOLVER_MATRICES_OUTPUT(GENERAL_OUTPUT_TYPE,SELECTION_TYPE,SOLVER_MATRICES,ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver solver matrices is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Solver equations solver mapping is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver dynamic solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_MATRICES_DYNAMIC_ASSEMBLE")
    RETURN
999 CALL ERRORS("SOLVER_MATRICES_DYNAMIC_ASSEMBLE",ERR,ERROR)
    CALL EXITS("SOLVER_MATRICES_DYNAMIC_ASSEMBLE")
    RETURN 1
  END SUBROUTINE SOLVER_MATRICES_DYNAMIC_ASSEMBLE

  !
  !================================================================================================================================
  !

  !>Assembles the solver matrices and rhs from the static equations.
  SUBROUTINE SOLVER_MATRICES_STATIC_ASSEMBLE(SOLVER,SELECTION_TYPE,ERR,ERROR,*)

    !Argument variableg
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the solver
    INTEGER(INTG), INTENT(IN) :: SELECTION_TYPE !<The type of matrix selection \see SOLVER_MATRICES_ROUTINES_SelectMatricesTypes,SOLVER_MATRICES_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DEPENDENT_VARIABLE_TYPE,equations_column_number,equations_matrix_idx,equations_matrix_number, &
      & equations_row_number,equations_row_number2,equations_set_idx,LINEAR_VARIABLE_TYPE,rhs_boundary_condition, &
      & residual_variable_type,rhs_global_dof,rhs_variable_dof,rhs_variable_type,variable_boundary_condition,solver_matrix_idx, &
      & solver_row_idx,solver_row_number,variable_dof,variable_global_dof,variable_idx,variable_type,&
      & j,dirichlet_idx,dirichlet_row,NUMBER_OF_NEUMANN_ROWS,rhs_dof
    REAL(SP) :: SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),USER_ELAPSED,USER_TIME1(1),USER_TIME2(1)
    REAL(DP) :: DEPENDENT_VALUE,LINEAR_VALUE,LINEAR_VALUE_SUM,MATRIX_VALUE,RESIDUAL_VALUE,RHS_VALUE,row_coupling_coefficient, &
      & SOURCE_VALUE,VALUE,INTEGRATED_VALUE
    REAL(DP), POINTER :: RHS_PARAMETERS(:)
    TYPE(REAL_DP_PTR_TYPE), ALLOCATABLE :: DEPENDENT_PARAMETERS(:)
    TYPE(BOUNDARY_CONDITIONS_TYPE), POINTER :: BOUNDARY_CONDITIONS
    TYPE(BOUNDARY_CONDITIONS_VARIABLE_TYPE), POINTER :: DEPENDENT_BOUNDARY_CONDITIONS,RHS_BOUNDARY_CONDITIONS
    TYPE(DISTRIBUTED_MATRIX_TYPE), POINTER :: PREVIOUS_SOLVER_DISTRIBUTED_MATRIX,SOLVER_DISTRIBUTED_MATRIX
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: DEPENDENT_VECTOR,DISTRIBUTED_SOURCE_VECTOR,EQUATIONS_RHS_VECTOR, &
      & LINEAR_TEMP_VECTOR,RESIDUAL_VECTOR,SOLVER_RESIDUAL_VECTOR,SOLVER_RHS_VECTOR
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: RESIDUAL_DOMAIN_MAPPING,RHS_DOMAIN_MAPPING,VARIABLE_DOMAIN_MAPPING
    TYPE(EQUATIONS_JACOBIAN_TYPE), POINTER :: JACOBIAN_MATRIX
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MAPPING_LINEAR_TYPE), POINTER :: LINEAR_MAPPING
    TYPE(EQUATIONS_MAPPING_NONLINEAR_TYPE), POINTER :: NONLINEAR_MAPPING
    TYPE(EQUATIONS_MAPPING_RHS_TYPE), POINTER :: RHS_MAPPING
    TYPE(EQUATIONS_MAPPING_SOURCE_TYPE), POINTER :: SOURCE_MAPPING
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_LINEAR_TYPE), POINTER :: LINEAR_MATRICES
    TYPE(EQUATIONS_MATRICES_NONLINEAR_TYPE), POINTER :: NONLINEAR_MATRICES
    TYPE(EQUATIONS_MATRICES_RHS_TYPE), POINTER :: RHS_VECTOR
    TYPE(EQUATIONS_MATRICES_SOURCE_TYPE), POINTER :: SOURCE_VECTOR
    TYPE(EQUATIONS_MATRIX_TYPE), POINTER :: EQUATIONS_MATRIX,LINEAR_MATRIX
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(EQUATIONS_TO_SOLVER_MAPS_TYPE), POINTER :: EQUATIONS_TO_SOLVER_MAP
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: DEPENDENT_VARIABLE,LINEAR_VARIABLE,RESIDUAL_VARIABLE,RHS_VARIABLE
    TYPE(JACOBIAN_TO_SOLVER_MAP_TYPE), POINTER :: JACOBIAN_TO_SOLVER_MAP
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(SOLVER_MATRIX_TYPE), POINTER :: SOLVER_MATRIX
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    TYPE(BOUNDARY_CONDITIONS_SPARSITY_INDICES_TYPE), POINTER :: SPARSITY_INDICES
   
    CALL ENTERS("SOLVER_MATRICES_STATIC_ASSEMBLE",ERR,ERROR,*999)
    IF(ASSOCIATED(SOLVER)) THEN
      SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
      IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
        SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
        IF(ASSOCIATED(SOLVER_MAPPING)) THEN
          SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
          IF(ASSOCIATED(SOLVER_MATRICES)) THEN
            !Assemble the solver matrices
            NULLIFY(PREVIOUS_SOLVER_DISTRIBUTED_MATRIX)
            IF(SELECTION_TYPE==SOLVER_MATRICES_ALL.OR. &
              & SELECTION_TYPE==SOLVER_MATRICES_LINEAR_ONLY.OR. &
              & SELECTION_TYPE==SOLVER_MATRICES_NONLINEAR_ONLY.OR. &
              & SELECTION_TYPE==SOLVER_MATRICES_JACOBIAN_ONLY) THEN
              !Assemble solver matrices
              IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
                CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
              ENDIF
              DO solver_matrix_idx=1,SOLVER_MAPPING%NUMBER_OF_SOLVER_MATRICES
                SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(solver_matrix_idx)%PTR
                IF(ASSOCIATED(SOLVER_MATRIX)) THEN
                  IF(SOLVER_MATRIX%UPDATE_MATRIX) THEN    
                    SOLVER_DISTRIBUTED_MATRIX=>SOLVER_MATRIX%MATRIX
                    IF(ASSOCIATED(SOLVER_DISTRIBUTED_MATRIX)) THEN                
                      !Initialise matrix to zero
                      CALL DISTRIBUTED_MATRIX_ALL_VALUES_SET(SOLVER_DISTRIBUTED_MATRIX,0.0_DP,ERR,ERROR,*999)
                      !Loop over the equations sets
                      DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                        !First Loop over the linear equations matrices
                        DO equations_matrix_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                          & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%NUMBER_OF_LINEAR_EQUATIONS_MATRICES
                          EQUATIONS_TO_SOLVER_MAP=>SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                            & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%LINEAR_EQUATIONS_TO_SOLVER_MATRIX_MAPS( &
                            & equations_matrix_idx)%PTR
                          IF(ASSOCIATED(EQUATIONS_TO_SOLVER_MAP)) THEN
                            EQUATIONS_MATRIX=>EQUATIONS_TO_SOLVER_MAP%EQUATIONS_MATRIX
                            IF(ASSOCIATED(EQUATIONS_MATRIX)) THEN
                              CALL SOLVER_MATRIX_EQUATIONS_MATRIX_ADD(SOLVER_MATRIX,equations_set_idx,1.0_DP,EQUATIONS_MATRIX, &
                                & ERR,ERROR,*999)
                            ELSE
                              CALL FLAG_ERROR("The equations matrix is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("The equations matrix equations to solver map is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ENDDO !equations_matrix_idx
                        IF(SELECTION_TYPE==SOLVER_MATRICES_ALL.OR. &
                          & SELECTION_TYPE==SOLVER_MATRICES_NONLINEAR_ONLY.OR. &
                          & SELECTION_TYPE==SOLVER_MATRICES_JACOBIAN_ONLY) THEN
                          !Now set the values from the equations Jacobian
                          JACOBIAN_TO_SOLVER_MAP=>SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                            & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%JACOBIAN_TO_SOLVER_MATRIX_MAP
                          IF(ASSOCIATED(JACOBIAN_TO_SOLVER_MAP)) THEN
                            JACOBIAN_MATRIX=>JACOBIAN_TO_SOLVER_MAP%JACOBIAN_MATRIX
                            IF(ASSOCIATED(JACOBIAN_MATRIX)) THEN
                              CALL SOLVER_MATRIX_JACOBIAN_MATRIX_ADD(SOLVER_MATRIX,equations_set_idx,1.0_DP,JACOBIAN_MATRIX, &
                                & ERR,ERROR,*999)
                            ELSE
                              CALL FLAG_ERROR("Jacobian matrix is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ENDIF
                        ENDIF
                      ENDDO !equations_set_idx
                      !Update the solver matrix values
                      CALL DISTRIBUTED_MATRIX_UPDATE_START(SOLVER_DISTRIBUTED_MATRIX,ERR,ERROR,*999)
                      IF(ASSOCIATED(PREVIOUS_SOLVER_DISTRIBUTED_MATRIX)) THEN
                        CALL DISTRIBUTED_MATRIX_UPDATE_FINISH(PREVIOUS_SOLVER_DISTRIBUTED_MATRIX,ERR,ERROR,*999)
                      ENDIF
                      PREVIOUS_SOLVER_DISTRIBUTED_MATRIX=>SOLVER_DISTRIBUTED_MATRIX
                    ELSE
                      CALL FLAG_ERROR("Solver matrix distributed matrix is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ENDIF !Update matrix
                ELSE
                  CALL FLAG_ERROR("Solver matrix is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDDO !solver_matrix_idx
              IF(ASSOCIATED(PREVIOUS_SOLVER_DISTRIBUTED_MATRIX)) THEN
                CALL DISTRIBUTED_MATRIX_UPDATE_FINISH(PREVIOUS_SOLVER_DISTRIBUTED_MATRIX,ERR,ERROR,*999)
              ENDIF
              IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
                CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
                USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
                SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for solver matrices assembly = ",USER_ELAPSED, &
                  & ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total System time for solver matrices assembly = ",SYSTEM_ELAPSED, &
                  & ERR,ERROR,*999)
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
              ENDIF
            ENDIF
            NULLIFY(SOLVER_RHS_VECTOR)
            IF(SELECTION_TYPE==SOLVER_MATRICES_ALL.OR. &
              & SELECTION_TYPE==SOLVER_MATRICES_LINEAR_ONLY.OR. &
              & SELECTION_TYPE==SOLVER_MATRICES_NONLINEAR_ONLY.OR. &
              & SELECTION_TYPE==SOLVER_MATRICES_RHS_ONLY.OR. &
              & SELECTION_TYPE==SOLVER_MATRICES_RHS_RESIDUAL_ONLY) THEN
              !Assemble rhs vector
              IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
                CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
              ENDIF
              IF(SOLVER_MATRICES%UPDATE_RHS_VECTOR) THEN
                SOLVER_RHS_VECTOR=>SOLVER_MATRICES%RHS_VECTOR
                IF(ASSOCIATED(SOLVER_RHS_VECTOR)) THEN
                  !Initialise the RHS to zero
                  CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(SOLVER_RHS_VECTOR,0.0_DP,ERR,ERROR,*999)            
                  !Loop over the equations sets
                  DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                    EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                    IF(ASSOCIATED(EQUATIONS_SET)) THEN
                      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                        EQUATIONS=>EQUATIONS_SET%EQUATIONS
                        IF(ASSOCIATED(EQUATIONS)) THEN
                          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                            EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                            IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                              SOURCE_MAPPING=>EQUATIONS_MAPPING%SOURCE_MAPPING
                              IF(ASSOCIATED(SOURCE_MAPPING)) THEN
                                SOURCE_VECTOR=>EQUATIONS_MATRICES%SOURCE_VECTOR
                                IF(ASSOCIATED(SOURCE_VECTOR)) THEN
                                  DISTRIBUTED_SOURCE_VECTOR=>SOURCE_VECTOR%VECTOR
                                ELSE
                                  CALL FLAG_ERROR("Source vector vector is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ENDIF
                              RHS_MAPPING=>EQUATIONS_MAPPING%RHS_MAPPING
                              IF(ASSOCIATED(RHS_MAPPING)) THEN
                                RHS_VARIABLE_TYPE=RHS_MAPPING%RHS_VARIABLE_TYPE
                                CALL FIELD_PARAMETER_SET_DATA_GET(DEPENDENT_FIELD,RHS_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                                  & RHS_PARAMETERS,ERR,ERROR,*999)
                                RHS_VECTOR=>EQUATIONS_MATRICES%RHS_VECTOR
                                IF(ASSOCIATED(RHS_VECTOR)) THEN
                                  LINEAR_MAPPING=>EQUATIONS_MAPPING%LINEAR_MAPPING
                                  NONLINEAR_MAPPING=>EQUATIONS_MAPPING%NONLINEAR_MAPPING
                                  IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                                    LINEAR_MATRICES=>EQUATIONS_MATRICES%LINEAR_MATRICES
                                    IF(ASSOCIATED(LINEAR_MATRICES)) THEN                                      
                                      ALLOCATE(DEPENDENT_PARAMETERS(LINEAR_MAPPING%NUMBER_OF_LINEAR_MATRIX_VARIABLES),STAT=ERR)
                                      IF(ERR/=0) CALL FLAG_ERROR("Could not allocate dependent_parameters.",ERR,ERROR,*999)
                                      DO variable_idx=1,LINEAR_MAPPING%NUMBER_OF_LINEAR_MATRIX_VARIABLES
                                        variable_type=LINEAR_MAPPING%LINEAR_MATRIX_VARIABLE_TYPES(variable_idx)
                                        NULLIFY(DEPENDENT_PARAMETERS(variable_idx)%PTR)
                                        CALL FIELD_PARAMETER_SET_DATA_GET(DEPENDENT_FIELD,variable_type,FIELD_VALUES_SET_TYPE, &
                                          & DEPENDENT_PARAMETERS(variable_idx)%PTR,ERR,ERROR,*999)
                                      ENDDO !variable_idx
                                    ELSE
                                      CALL FLAG_ERROR("Equations matrices linear matrices is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ENDIF
                                  BOUNDARY_CONDITIONS=>EQUATIONS_SET%BOUNDARY_CONDITIONS
                                  IF(ASSOCIATED(BOUNDARY_CONDITIONS)) THEN
!!TODO: what if the equations set doesn't have a RHS vector???
                                    RHS_VARIABLE=>RHS_MAPPING%RHS_VARIABLE
                                    RHS_VARIABLE_TYPE=RHS_VARIABLE%VARIABLE_TYPE
                                    RHS_DOMAIN_MAPPING=>RHS_VARIABLE%DOMAIN_MAPPING
                                    EQUATIONS_RHS_VECTOR=>RHS_VECTOR%VECTOR
                                    RHS_BOUNDARY_CONDITIONS=>BOUNDARY_CONDITIONS%BOUNDARY_CONDITIONS_VARIABLE_TYPE_MAP( &
                                      & RHS_VARIABLE_TYPE)%PTR
                                    IF(ASSOCIATED(RHS_BOUNDARY_CONDITIONS)) THEN


!-----------------------------------------------------------------------------------------------------------------------
!Routine to assemble integrated flux values - section below to be moved to BOUNDARY_CONDITIONS_INTEGRATED_CALCULATE

                                      !Count the number of Neumann conditions set
                                      NUMBER_OF_NEUMANN_ROWS=0
                                      DO equations_row_number=1,EQUATIONS_MAPPING%TOTAL_NUMBER_OF_ROWS
                                        rhs_variable_dof=RHS_MAPPING%EQUATIONS_ROW_TO_RHS_DOF_MAP(equations_row_number)
                                        rhs_global_dof=RHS_DOMAIN_MAPPING%LOCAL_TO_GLOBAL_MAP(rhs_variable_dof)
                                        rhs_boundary_condition=RHS_BOUNDARY_CONDITIONS%GLOBAL_BOUNDARY_CONDITIONS(rhs_global_dof)
                                        IF(rhs_boundary_condition==BOUNDARY_CONDITION_NEUMANN) THEN
                                          NUMBER_OF_NEUMANN_ROWS=NUMBER_OF_NEUMANN_ROWS+1
                                        ENDIF
                                      ENDDO !equations_row_number

                                      !Calculate the Neumann integrated flux boundary conditions
                                      IF(NUMBER_OF_NEUMANN_ROWS>0) THEN

                                        CALL BOUNDARY_CONDITIONS_INTEGRATED_CALCULATE(BOUNDARY_CONDITIONS, &
                                          & RHS_VARIABLE_TYPE,ERR,ERROR,*999)

                                        !Locate calculated value at dof
                                        INTEGRATED_VALUE=0.0_DP
                                        DO j=1,RHS_BOUNDARY_CONDITIONS%NEUMANN_BOUNDARY_CONDITIONS &
                                          & %INTEGRATED_VALUES_VECTOR_SIZE

                                          INTEGRATED_VALUE=RHS_BOUNDARY_CONDITIONS &
                                            & %NEUMANN_BOUNDARY_CONDITIONS%INTEGRATED_VALUES_VECTOR(j)
                                          rhs_dof=RHS_BOUNDARY_CONDITIONS &
                                            & %NEUMANN_BOUNDARY_CONDITIONS%INTEGRATED_VALUES_VECTOR_MAPPING(j)

                                          !Note: check whether MAPPING dofs are local or global

                                          CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD, &
                                            & rhs_variable_type,FIELD_VALUES_SET_TYPE, &
                                            & rhs_dof,INTEGRATED_VALUE,ERR,ERROR,*999)
                                        ENDDO !j

                                        DEALLOCATE(RHS_BOUNDARY_CONDITIONS%NEUMANN_BOUNDARY_CONDITIONS% &
                                          & INTEGRATED_VALUES_VECTOR_MAPPING)
                                        DEALLOCATE(RHS_BOUNDARY_CONDITIONS%NEUMANN_BOUNDARY_CONDITIONS% &
                                          & INTEGRATED_VALUES_VECTOR)
                                      ENDIF

!-------------------------------------------------------------------------------------------------------------------------


                                      !Loop over the rows in the equations set
                                      DO equations_row_number=1,EQUATIONS_MAPPING%TOTAL_NUMBER_OF_ROWS
                                        !Get the source vector contribute to the RHS values if there are any
                                        IF(ASSOCIATED(SOURCE_MAPPING)) THEN
                                          !Add in equations source values
                                          CALL DISTRIBUTED_VECTOR_VALUES_GET(DISTRIBUTED_SOURCE_VECTOR,equations_row_number, &
                                            & SOURCE_VALUE,ERR,ERROR,*999)
                                          !Loop over the solver rows associated with this equations set row
                                          DO solver_row_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                            & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%NUMBER_OF_SOLVER_ROWS

                                            solver_row_number=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                              & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%SOLVER_ROWS( &
                                              & solver_row_idx)

                                            row_coupling_coefficient=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP( &
                                              & equations_set_idx)%EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
                                              & COUPLING_COEFFICIENTS(solver_row_idx)

                                            VALUE=SOURCE_VALUE*row_coupling_coefficient

                                            !Calculates the contribution from each row of the equations matrix and adds to solver matrix
                                            CALL DISTRIBUTED_VECTOR_VALUES_ADD(SOLVER_RHS_VECTOR,solver_row_number,VALUE, &
                                              & ERR,ERROR,*999)
                                          ENDDO !solver_row_idx
                                        ENDIF
                                        rhs_variable_dof=RHS_MAPPING%EQUATIONS_ROW_TO_RHS_DOF_MAP(equations_row_number)
                                        rhs_global_dof=RHS_DOMAIN_MAPPING%LOCAL_TO_GLOBAL_MAP(rhs_variable_dof)
                                        rhs_boundary_condition=RHS_BOUNDARY_CONDITIONS%GLOBAL_BOUNDARY_CONDITIONS(rhs_global_dof)
                                        !Apply boundary conditions
                                        SELECT CASE(rhs_boundary_condition)
                                        CASE(BOUNDARY_CONDITION_NOT_FIXED,BOUNDARY_CONDITION_FREE_WALL)
                                          !Add in equations RHS values
                                          CALL DISTRIBUTED_VECTOR_VALUES_GET(EQUATIONS_RHS_VECTOR,equations_row_number, &
                                            & RHS_VALUE,ERR,ERROR,*999)

                                          !Loop over the solver rows associated with this equations set row
                                          DO solver_row_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                            & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%NUMBER_OF_SOLVER_ROWS

                                            solver_row_number=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                              & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%SOLVER_ROWS( &
                                              & solver_row_idx)

                                            row_coupling_coefficient=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP( &
                                              & equations_set_idx)%EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
                                              & COUPLING_COEFFICIENTS(solver_row_idx)

                                            VALUE=RHS_VALUE*row_coupling_coefficient

                                            CALL DISTRIBUTED_VECTOR_VALUES_ADD(SOLVER_RHS_VECTOR,solver_row_number,VALUE, &
                                              & ERR,ERROR,*999)
                                          ENDDO !solver_row_idx                          
                                          !Set Dirichlet boundary conditions
                                          IF(ASSOCIATED(LINEAR_MAPPING).AND..NOT.ASSOCIATED(NONLINEAR_MAPPING)) THEN
                                            !Loop over the dependent variables associated with this equations set row
                                            DO variable_idx=1,LINEAR_MAPPING%NUMBER_OF_LINEAR_MATRIX_VARIABLES

                                              variable_type=LINEAR_MAPPING%LINEAR_MATRIX_VARIABLE_TYPES(variable_idx)

                                              DEPENDENT_VARIABLE=>LINEAR_MAPPING%VAR_TO_EQUATIONS_MATRICES_MAPS( &
                                                & variable_type)%VARIABLE

                                              DEPENDENT_VARIABLE_TYPE=DEPENDENT_VARIABLE%VARIABLE_TYPE
                                              VARIABLE_DOMAIN_MAPPING=>DEPENDENT_VARIABLE%DOMAIN_MAPPING

                                              DEPENDENT_BOUNDARY_CONDITIONS=>BOUNDARY_CONDITIONS% &
                                                & BOUNDARY_CONDITIONS_VARIABLE_TYPE_MAP(DEPENDENT_VARIABLE_TYPE)%PTR

                                              variable_dof=LINEAR_MAPPING%EQUATIONS_ROW_TO_VARIABLE_DOF_MAPS( &
                                                & equations_row_number,variable_idx)

                                              variable_global_dof=VARIABLE_DOMAIN_MAPPING%LOCAL_TO_GLOBAL_MAP(variable_dof)

                                              variable_boundary_condition=DEPENDENT_BOUNDARY_CONDITIONS% &
                                                & GLOBAL_BOUNDARY_CONDITIONS(variable_global_dof)

                                              IF(variable_boundary_condition==BOUNDARY_CONDITION_FIXED.OR. & 
                                                & variable_boundary_condition==BOUNDARY_CONDITION_FIXED_INLET.OR. &
                                                & variable_boundary_condition==BOUNDARY_CONDITION_FIXED_OUTLET.OR. &  
                                                & variable_boundary_condition==BOUNDARY_CONDITION_FIXED_WALL.OR. & 
                                                & variable_boundary_condition==BOUNDARY_CONDITION_MOVED_WALL) THEN


                                                DEPENDENT_VALUE=DEPENDENT_PARAMETERS(variable_idx)%PTR(variable_dof)

                                                IF(ABS(DEPENDENT_VALUE)>=ZERO_TOLERANCE) THEN
                                                  DO equations_matrix_idx=1,LINEAR_MAPPING%VAR_TO_EQUATIONS_MATRICES_MAPS( &
                                                    & variable_type)%NUMBER_OF_EQUATIONS_MATRICES

                                                    equations_matrix_number=LINEAR_MAPPING%VAR_TO_EQUATIONS_MATRICES_MAPS( &
                                                      & variable_type)%EQUATIONS_MATRIX_NUMBERS(equations_matrix_idx)

                                                    EQUATIONS_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_number)%PTR

                                                    equations_column_number=LINEAR_MAPPING%VAR_TO_EQUATIONS_MATRICES_MAPS( &
                                                      & variable_type)%DOF_TO_COLUMNS_MAPS(equations_matrix_idx)%COLUMN_DOF( &
                                                      & variable_dof)
                                                    IF(ASSOCIATED(DEPENDENT_BOUNDARY_CONDITIONS%DIRICHLET_BOUNDARY_CONDITIONS)) THEN
                                                      IF(DEPENDENT_BOUNDARY_CONDITIONS%NUMBER_OF_DIRICHLET_CONDITIONS>0) THEN
                                                        DO dirichlet_idx=1,DEPENDENT_BOUNDARY_CONDITIONS% &
                                                          & NUMBER_OF_DIRICHLET_CONDITIONS
                                                          IF(DEPENDENT_BOUNDARY_CONDITIONS%DIRICHLET_BOUNDARY_CONDITIONS% &
                                                            & DIRICHLET_DOF_INDICES(dirichlet_idx)==equations_column_number) EXIT
                                                        ENDDO
                                                        SPARSITY_INDICES=>DEPENDENT_BOUNDARY_CONDITIONS% &
                                                          & DIRICHLET_BOUNDARY_CONDITIONS%LINEAR_SPARSITY_INDICES( &
                                                          & equations_matrix_idx)%PTR
                                                        IF(ASSOCIATED(SPARSITY_INDICES)) THEN
                                                          DO equations_row_number2=SPARSITY_INDICES%SPARSE_COLUMN_INDICES( &
                                                            & dirichlet_idx),SPARSITY_INDICES%SPARSE_COLUMN_INDICES( &
                                                            & dirichlet_idx+1)-1
                                                            dirichlet_row=SPARSITY_INDICES%SPARSE_ROW_INDICES(equations_row_number2)
                                                            CALL DISTRIBUTED_MATRIX_VALUES_GET(EQUATIONS_MATRIX%MATRIX, &
                                                              & dirichlet_row,equations_column_number,MATRIX_VALUE,ERR,ERROR,*999)
                                                            IF(ABS(MATRIX_VALUE)>=ZERO_TOLERANCE) THEN
                                                              DO solver_row_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP( &
                                                                & equations_set_idx)%EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS( &
                                                                & dirichlet_row)%NUMBER_OF_SOLVER_ROWS
                                                                solver_row_number=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP( &
                                                                  & equations_set_idx)%EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS( &
                                                                  & dirichlet_row)%SOLVER_ROWS(solver_row_idx)
                                                                row_coupling_coefficient=SOLVER_MAPPING% &
                                                                  & EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                                                  & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(dirichlet_row)% &
                                                                  & COUPLING_COEFFICIENTS(solver_row_idx)
                                                                VALUE=-1.0_DP*MATRIX_VALUE*DEPENDENT_VALUE*row_coupling_coefficient
                                                                CALL DISTRIBUTED_VECTOR_VALUES_ADD(SOLVER_RHS_VECTOR, &
                                                                  & solver_row_number,VALUE,ERR,ERROR,*999)
                                                              ENDDO !solver_row_idx
                                                            ENDIF
                                                          ENDDO !equations_row_number2
                                                        ELSE
                                                          CALL FLAG_ERROR("Sparsity indices are not associated.",ERR,ERROR,*999)
                                                        ENDIF
                                                      ENDIF
                                                    ELSE
                                                      CALL FLAG_ERROR("Dirichlet boundary conditions is not associated.",ERR, &
                                                        & ERROR,*999)
                                                    ENDIF
                                                  ENDDO !matrix_idx
                                                ENDIF
                                              ENDIF
                                            ENDDO !variable_idx
                                          ENDIF

                                        CASE(BOUNDARY_CONDITION_FIXED,BOUNDARY_CONDITION_NEUMANN)
                                          RHS_VALUE=RHS_PARAMETERS(rhs_variable_dof)
                                          IF(ABS(RHS_VALUE)>=ZERO_TOLERANCE) THEN
                                            !Loop over the solver rows associated with this equations set row
                                            DO solver_row_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                              & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%NUMBER_OF_SOLVER_ROWS
                                              solver_row_number=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                                & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%SOLVER_ROWS( &
                                                & solver_row_idx)
                                              row_coupling_coefficient=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP( &
                                                & equations_set_idx)%EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
                                                & COUPLING_COEFFICIENTS(solver_row_idx)
                                              VALUE=RHS_VALUE*row_coupling_coefficient

                                              CALL DISTRIBUTED_VECTOR_VALUES_ADD(SOLVER_RHS_VECTOR,solver_row_number,VALUE, &
                                                & ERR,ERROR,*999)
                                            ENDDO !solver_row_idx
                                          ENDIF

                                        CASE(BOUNDARY_CONDITION_MIXED)
                                          !Set Robin or is it Cauchy??? boundary conditions
                                          CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)

                                        CASE DEFAULT
                                          LOCAL_ERROR="The RHS boundary condition of "// &
                                            & TRIM(NUMBER_TO_VSTRING(rhs_boundary_condition,"*",ERR,ERROR))// &
                                            & " for RHS variable dof number "// &
                                            & TRIM(NUMBER_TO_VSTRING(rhs_variable_dof,"*",ERR,ERROR))//" is invalid."
                                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                                        END SELECT
                                      ENDDO !equations_row_number
                                    ELSE
                                      CALL FLAG_ERROR("RHS boundary conditions variable is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ELSE
                                    CALL FLAG_ERROR("Equations set boundary conditions is not associated.",ERR,ERROR,*999)
                                  ENDIF
                                  IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                                    DO variable_idx=1,LINEAR_MAPPING%NUMBER_OF_LINEAR_MATRIX_VARIABLES
                                      variable_type=LINEAR_MAPPING%LINEAR_MATRIX_VARIABLE_TYPES(variable_idx)
                                      CALL FIELD_PARAMETER_SET_DATA_RESTORE(DEPENDENT_FIELD,variable_type,FIELD_VALUES_SET_TYPE, &
                                        & DEPENDENT_PARAMETERS(variable_idx)%PTR,ERR,ERROR,*999)
                                    ENDDO !variable_idx
                                    IF(ALLOCATED(DEPENDENT_PARAMETERS)) DEALLOCATE(DEPENDENT_PARAMETERS)
                                  ENDIF
                                ELSE
                                  CALL FLAG_ERROR("Equations matrices RHS vector is not associated.",ERR,ERROR,*999)
                                ENDIF
                                CALL FIELD_PARAMETER_SET_DATA_RESTORE(DEPENDENT_FIELD,RHS_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                                  & RHS_PARAMETERS,ERR,ERROR,*999)
                              ELSE
                                CALL FLAG_ERROR("Equations mapping RHS mapping is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              CALL FLAG_ERROR("Equations equations mapping is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("Equations equations matrices is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Equations set equations is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ENDIF
                  ENDDO !equations_set_idx
                  !Start the update the solver RHS vector values
                  CALL DISTRIBUTED_VECTOR_UPDATE_START(SOLVER_RHS_VECTOR,ERR,ERROR,*999)
                ELSE
                  CALL FLAG_ERROR("The solver RHS vector is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDIF
              IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
                CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
                USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
                SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for solver RHS assembly = ",USER_ELAPSED, &
                  & ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total System time for solver RHS assembly = ",SYSTEM_ELAPSED, &
                  & ERR,ERROR,*999)
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
              ENDIF
            ENDIF
            IF(SELECTION_TYPE==SOLVER_MATRICES_ALL.OR. &
              & SELECTION_TYPE==SOLVER_MATRICES_NONLINEAR_ONLY.OR. &
              & SELECTION_TYPE==SOLVER_MATRICES_RESIDUAL_ONLY.OR. &
              & SELECTION_TYPE==SOLVER_MATRICES_RHS_RESIDUAL_ONLY) THEN
              !Assemble residual vector
              IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
                CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)
              ENDIF

              NULLIFY(SOLVER_RESIDUAL_VECTOR)
              IF(SOLVER_MATRICES%UPDATE_RESIDUAL) THEN           
                SOLVER_RESIDUAL_VECTOR=>SOLVER_MATRICES%RESIDUAL
                IF(ASSOCIATED(SOLVER_RESIDUAL_VECTOR)) THEN
                  !Initialise the residual to zero              
                  CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(SOLVER_RESIDUAL_VECTOR,0.0_DP,ERR,ERROR,*999)       
                  !Loop over the equations sets
                  DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                    EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                    IF(ASSOCIATED(EQUATIONS_SET)) THEN
                      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                      IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                        EQUATIONS=>EQUATIONS_SET%EQUATIONS
                        IF(ASSOCIATED(EQUATIONS)) THEN
                          EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                          IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                            EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                            IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                              !Calculate the contributions from any linear matrices 
                              LINEAR_MAPPING=>EQUATIONS_MAPPING%LINEAR_MAPPING
                              IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                                LINEAR_MATRICES=>EQUATIONS_MATRICES%LINEAR_MATRICES
                                IF(ASSOCIATED(LINEAR_MATRICES)) THEN
                                  DO equations_matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                                    LINEAR_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_idx)%PTR
                                    IF(ASSOCIATED(LINEAR_MATRIX)) THEN
                                      LINEAR_VARIABLE_TYPE=LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)% &
                                        & VARIABLE_TYPE
                                      LINEAR_VARIABLE=>LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)% &
                                        & VARIABLE
                                      IF(ASSOCIATED(LINEAR_VARIABLE)) THEN
                                        LINEAR_TEMP_VECTOR=>LINEAR_MATRIX%TEMP_VECTOR
                                        !Initialise the linear temporary vector to zero
                                        CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(LINEAR_TEMP_VECTOR,0.0_DP,ERR,ERROR,*999)
                                        NULLIFY(DEPENDENT_VECTOR)
                                        CALL FIELD_PARAMETER_SET_VECTOR_GET(DEPENDENT_FIELD,LINEAR_VARIABLE_TYPE, &
                                          & FIELD_VALUES_SET_TYPE,DEPENDENT_VECTOR,ERR,ERROR,*999)
                                        CALL DISTRIBUTED_MATRIX_BY_VECTOR_ADD(DISTRIBUTED_MATRIX_VECTOR_NO_GHOSTS_TYPE,1.0_DP, &
                                          & LINEAR_MATRIX%MATRIX,DEPENDENT_VECTOR,LINEAR_TEMP_VECTOR,ERR,ERROR,*999)
                                      ELSE
                                        CALL FLAG_ERROR("Linear variable is not associated.",ERR,ERROR,*999)
                                      ENDIF
                                    ELSE
                                      LOCAL_ERROR="Linear matrix is not associated for linear matrix number "// &
                                        & TRIM(NUMBER_TO_VSTRING(equations_matrix_idx,"*",ERR,ERROR))//"."
                                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                                    ENDIF
                                  ENDDO !equations_matrix_idx
                                ELSE
                                  CALL FLAG_ERROR("Equations matrices linear matrices is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ENDIF
                              !Calculate the solver residual
                              NONLINEAR_MAPPING=>EQUATIONS_MAPPING%NONLINEAR_MAPPING
                              IF(ASSOCIATED(NONLINEAR_MAPPING)) THEN
                                NONLINEAR_MATRICES=>EQUATIONS_MATRICES%NONLINEAR_MATRICES
                                IF(ASSOCIATED(NONLINEAR_MATRICES)) THEN
                                  residual_variable_type=NONLINEAR_MAPPING%RESIDUAL_VARIABLE_TYPE
                                  RESIDUAL_VARIABLE=>NONLINEAR_MAPPING%RESIDUAL_VARIABLE
                                  RESIDUAL_DOMAIN_MAPPING=>RESIDUAL_VARIABLE%DOMAIN_MAPPING
                                  RESIDUAL_VECTOR=>NONLINEAR_MATRICES%RESIDUAL
                                  !Loop over the rows in the equations set
                                  DO equations_row_number=1,EQUATIONS_MAPPING%NUMBER_OF_ROWS
                                    IF(SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                      & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
                                      & NUMBER_OF_SOLVER_ROWS>0) THEN
                                      !Get the equations residual contribution
                                      CALL DISTRIBUTED_VECTOR_VALUES_GET(RESIDUAL_VECTOR,equations_row_number, &
                                        & RESIDUAL_VALUE,ERR,ERROR,*999)
                                      !Get the linear matrices contribution to the RHS values if there are any
                                      IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                                        LINEAR_VALUE_SUM=0.0_DP
                                        DO equations_matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                                          LINEAR_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_idx)%PTR
                                          LINEAR_TEMP_VECTOR=>LINEAR_MATRIX%TEMP_VECTOR
                                          CALL DISTRIBUTED_VECTOR_VALUES_GET(LINEAR_TEMP_VECTOR,equations_row_number, &
                                            & LINEAR_VALUE,ERR,ERROR,*999)
                                          LINEAR_VALUE_SUM=LINEAR_VALUE_SUM+LINEAR_VALUE
                                        ENDDO !equations_matrix_idx
                                        RESIDUAL_VALUE=RESIDUAL_VALUE+LINEAR_VALUE_SUM
                                      ENDIF
                                      !Loop over the solver rows associated with this equations set residual row
                                      DO solver_row_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                        & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%NUMBER_OF_SOLVER_ROWS
                                        solver_row_number=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                          & EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)%SOLVER_ROWS( &
                                          & solver_row_idx)
                                        row_coupling_coefficient=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP( &
                                          & equations_set_idx)%EQUATIONS_ROW_TO_SOLVER_ROWS_MAPS(equations_row_number)% &
                                          & COUPLING_COEFFICIENTS(solver_row_idx)
                                        VALUE=RESIDUAL_VALUE*row_coupling_coefficient
                                        !Add in nonlinear residual values                                    
                                        CALL DISTRIBUTED_VECTOR_VALUES_ADD(SOLVER_RESIDUAL_VECTOR,solver_row_number,VALUE, &
                                          & ERR,ERROR,*999)
                                      ENDDO !solver_row_idx
                                    ENDIF
                                  ENDDO !equations_row_number
                                ELSE
                                  CALL FLAG_ERROR("Equations matrices nonlinear matrices is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                CALL FLAG_ERROR("Equations mapping nonlinear mapping is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              CALL FLAG_ERROR("Equations equations mapping is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("Equations equations matrices is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Equations set equations is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        CALL FLAG_ERROR("Equations set dependent field is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ENDDO !equations_set_idx
                  !Start the update the solver residual vector values
                  CALL DISTRIBUTED_VECTOR_UPDATE_START(SOLVER_RESIDUAL_VECTOR,ERR,ERROR,*999)
                ELSE
                  CALL FLAG_ERROR("The solver residual vector is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDIF
              IF(ASSOCIATED(SOLVER_RESIDUAL_VECTOR)) THEN
                CALL DISTRIBUTED_VECTOR_UPDATE_FINISH(SOLVER_RESIDUAL_VECTOR,ERR,ERROR,*999)
              ENDIF
              IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
                CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
                CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
                USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
                SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for solver residual assembly = ",USER_ELAPSED, &
                  & ERR,ERROR,*999)
                CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total System time for solver residual assembly = ",SYSTEM_ELAPSED, &
                  & ERR,ERROR,*999)
                CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
              ENDIF
            ENDIF
            IF(ASSOCIATED(SOLVER_RHS_VECTOR)) THEN
              CALL DISTRIBUTED_VECTOR_UPDATE_FINISH(SOLVER_RHS_VECTOR,ERR,ERROR,*999)
            ENDIF
            !If required output the solver matrices          
            IF(SOLVER%OUTPUT_TYPE>=SOLVER_MATRIX_OUTPUT) THEN
              CALL SOLVER_MATRICES_OUTPUT(GENERAL_OUTPUT_TYPE,SELECTION_TYPE,SOLVER_MATRICES,ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Solver solver matrices is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver matrices solution mapping is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF

    CALL EXITS("SOLVER_MATRICES_STATIC_ASSEMBLE")
    RETURN
999 IF(ALLOCATED(DEPENDENT_PARAMETERS)) DEALLOCATE(DEPENDENT_PARAMETERS)    
    CALL ERRORS("SOLVER_MATRICES_STATIC_ASSEMBLE",ERR,ERROR)
    CALL EXITS("SOLVER_MATRICES_STATIC_ASSEMBLE")
    RETURN 1
  END SUBROUTINE SOLVER_MATRICES_STATIC_ASSEMBLE

  !
  !================================================================================================================================
  !

  !>Gets the type of library to use for the solver matrices 
  SUBROUTINE SOLVER_MATRICES_LIBRARY_TYPE_GET(SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to get the matrices library type of
    INTEGER(INTG), INTENT(OUT) :: MATRICES_LIBRARY_TYPE !<On exit, the type of library used for the solver matrices \see DISTRIBUTED_MATRIX_VECTOR_LibraryTypes,DISTRIBUTED_MATRIX_VECTOR
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(EIGENPROBLEM_SOLVER_TYPE), POINTER :: EIGENPROBLEM_SOLVER
    TYPE(LINEAR_SOLVER_TYPE), POINTER :: LINEAR_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(OPTIMISER_SOLVER_TYPE), POINTER :: OPTIMISER_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      SELECT CASE(SOLVER%SOLVE_TYPE)
      CASE(SOLVER_LINEAR_TYPE)
        LINEAR_SOLVER=>SOLVER%LINEAR_SOLVER
        IF(ASSOCIATED(LINEAR_SOLVER)) THEN
          CALL SOLVER_LINEAR_MATRICES_LIBRARY_TYPE_GET(LINEAR_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Solver linear solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_NONLINEAR_TYPE)
        NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
        IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
          CALL SOLVER_NONLINEAR_MATRICES_LIBRARY_TYPE_GET(NONLINEAR_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Solver nonlinear solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_DYNAMIC_TYPE)
        CALL FLAG_ERROR("Cannot get the solver matrices library for a dynamic solver.",ERR,ERROR,*999)
      CASE(SOLVER_DAE_TYPE)
        CALL FLAG_ERROR("Cannot get the solver matrices library for an differential-algebraic equations solver.",ERR,ERROR,*999)
      CASE(SOLVER_EIGENPROBLEM_TYPE)
        EIGENPROBLEM_SOLVER=>SOLVER%EIGENPROBLEM_SOLVER
        IF(ASSOCIATED(EIGENPROBLEM_SOLVER)) THEN
          CALL SOLVER_EIGENPROBLEM_MATRICES_LIBRARY_TYPE_GET(EIGENPROBLEM_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Solver eigenproblem solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_OPTIMISER_TYPE)
        OPTIMISER_SOLVER=>SOLVER%OPTIMISER_SOLVER
        IF(ASSOCIATED(OPTIMISER_SOLVER)) THEN
          CALL SOLVER_OPTIMISER_MATRICES_LIBRARY_TYPE_GET(OPTIMISER_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Solver optimiser solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The solver type of "//TRIM(NUMBER_TO_VSTRING(SOLVER%SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_MATRICES_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_MATRICES_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_MATRICES_LIBRARY_TYPE_GET
  
  !
  !================================================================================================================================
  !

  !>Sets/changes the maximum absolute tolerance for a nonlinear Newton solver. \todo should this be SOLVER_NONLINEAR_NEWTON_ABSOLUTE_TOLERANCE_SET??? \see OPENCMISS::CMISSSolverNewtonAbsoluteToleranceSet
  SUBROUTINE SOLVER_NEWTON_ABSOLUTE_TOLERANCE_SET(SOLVER,ABSOLUTE_TOLERANCE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the absolute tolerance for
    REAL(DP), INTENT(IN) :: ABSOLUTE_TOLERANCE !<The absolute tolerance to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_ABSOLUTE_TOLERANCE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(ABSOLUTE_TOLERANCE>ZERO_TOLERANCE) THEN
                  NEWTON_SOLVER%ABSOLUTE_TOLERANCE=ABSOLUTE_TOLERANCE
                ELSE
                  LOCAL_ERROR="The specified absolute tolerance of "//TRIM(NUMBER_TO_VSTRING(ABSOLUTE_TOLERANCE,"*",ERR,ERROR))// &
                    & " is invalid. The absolute tolerance must be > 0."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_ABSOLUTE_TOLERANCE_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_ABSOLUTE_TOLERANCE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_ABSOLUTE_TOLERANCE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_ABSOLUTE_TOLERANCE_SET
        
  !
  !================================================================================================================================
  !

  !>Finishes the process of creating a Newton solver 
  SUBROUTINE SOLVER_NEWTON_CREATE_FINISH(NEWTON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER !<A pointer to the Newton solver to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_NEWTON_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(NEWTON_SOLVER)) THEN
      SELECT CASE(NEWTON_SOLVER%NEWTON_SOLVE_TYPE)
      CASE(SOLVER_NEWTON_LINESEARCH)
        CALL SOLVER_NEWTON_LINESEARCH_CREATE_FINISH(NEWTON_SOLVER%LINESEARCH_SOLVER,ERR,ERROR,*999)
      CASE(SOLVER_NEWTON_TRUSTREGION)
        CALL SOLVER_NEWTON_TRUSTREGION_CREATE_FINISH(NEWTON_SOLVER%TRUSTREGION_SOLVER,ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The Newton solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVER%NEWTON_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Newton solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_NEWTON_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_CREATE_FINISH")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Finalise a Newton solver and deallocate all memory
  SUBROUTINE SOLVER_NEWTON_FINALISE(NEWTON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER !<A pointer the Newton solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_NEWTON_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(NEWTON_SOLVER)) THEN
      CALL SOLVER_NEWTON_LINESEARCH_FINALISE(NEWTON_SOLVER%LINESEARCH_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_NEWTON_TRUSTREGION_FINALISE(NEWTON_SOLVER%TRUSTREGION_SOLVER,ERR,ERROR,*999)
      CALL SOLVER_FINALISE(NEWTON_SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
      DEALLOCATE(NEWTON_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_NEWTON_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a Newton solver for a nonlinear solver
  SUBROUTINE SOLVER_NEWTON_INITIALISE(NONLINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER !<A pointer the solver to initialise the Newton solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(VARYING_STRING) :: DUMMY_ERROR
 
    CALL ENTERS("SOLVER_NEWTON_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
      IF(ASSOCIATED(NONLINEAR_SOLVER%NEWTON_SOLVER)) THEN
        CALL FLAG_ERROR("Newton solver is already associated for this nonlinear solver.",ERR,ERROR,*998)
      ELSE        
        SOLVER=>NONLINEAR_SOLVER%SOLVER
        IF(ASSOCIATED(SOLVER)) THEN
          !Allocate and initialise a Newton solver
          ALLOCATE(NONLINEAR_SOLVER%NEWTON_SOLVER,STAT=ERR)
          IF(ERR/=0) CALL FLAG_ERROR("Could not allocate nonlinear solver Newton solver.",ERR,ERROR,*999)
          NONLINEAR_SOLVER%NEWTON_SOLVER%NONLINEAR_SOLVER=>NONLINEAR_SOLVER
          NONLINEAR_SOLVER%NEWTON_SOLVER%SOLUTION_INITIALISE_TYPE=SOLVER_SOLUTION_INITIALISE_CURRENT_FIELD
          NONLINEAR_SOLVER%NEWTON_SOLVER%TOTAL_NUMBER_OF_FUNCTION_EVALUATIONS=0
          NONLINEAR_SOLVER%NEWTON_SOLVER%TOTAL_NUMBER_OF_JACOBIAN_EVALUATIONS=0
          NONLINEAR_SOLVER%NEWTON_SOLVER%MAXIMUM_NUMBER_OF_ITERATIONS=50
          NONLINEAR_SOLVER%NEWTON_SOLVER%MAXIMUM_NUMBER_OF_FUNCTION_EVALUATIONS=1000
          NONLINEAR_SOLVER%NEWTON_SOLVER%JACOBIAN_CALCULATION_TYPE=SOLVER_NEWTON_JACOBIAN_FD_CALCULATED
          NONLINEAR_SOLVER%NEWTON_SOLVER%ABSOLUTE_TOLERANCE=1.0E-10_DP
          NONLINEAR_SOLVER%NEWTON_SOLVER%RELATIVE_TOLERANCE=1.0E-05_DP
          NONLINEAR_SOLVER%NEWTON_SOLVER%SOLUTION_TOLERANCE=1.0E-05_DP
          NULLIFY(NONLINEAR_SOLVER%NEWTON_SOLVER%LINESEARCH_SOLVER)
          NULLIFY(NONLINEAR_SOLVER%NEWTON_SOLVER%TRUSTREGION_SOLVER)
          !Default to a Newton linesearch solver
          NONLINEAR_SOLVER%NEWTON_SOLVER%NEWTON_SOLVE_TYPE=SOLVER_NEWTON_LINESEARCH
          CALL SOLVER_NEWTON_LINESEARCH_INITIALISE(NONLINEAR_SOLVER%NEWTON_SOLVER,ERR,ERROR,*999)
          !Create the linked linear solver
          ALLOCATE(NONLINEAR_SOLVER%NEWTON_SOLVER%LINEAR_SOLVER,STAT=ERR)
          IF(ERR/=0) CALL FLAG_ERROR("Could not allocate Newton solver linear solver.",ERR,ERROR,*999)
          NULLIFY(NONLINEAR_SOLVER%NEWTON_SOLVER%LINEAR_SOLVER%SOLVERS)
          CALL SOLVER_INITIALISE_PTR(NONLINEAR_SOLVER%NEWTON_SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
          SOLVER%LINKED_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER%LINEAR_SOLVER
          NONLINEAR_SOLVER%NEWTON_SOLVER%LINEAR_SOLVER%LINKING_SOLVER=>SOLVER
          NONLINEAR_SOLVER%NEWTON_SOLVER%LINEAR_SOLVER%SOLVE_TYPE=SOLVER_LINEAR_TYPE
          CALL SOLVER_LINEAR_INITIALISE(NONLINEAR_SOLVER%NEWTON_SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Nonlinear solver solver is not associated.",ERR,ERROR,*998)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Nonlinear solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_NEWTON_INITIALISE")
    RETURN
999 CALL SOLVER_NEWTON_FINALISE(NONLINEAR_SOLVER%NEWTON_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_NEWTON_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_INITIALISE

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of Jacobian calculation type for a Newton solver. \todo should this be SOLVER_NONLINEAR_NEWTON_JACOBIAN_CALCULATION_SET??? \see OPENCMISS::CMISSSolverNewtonJacobianCalculationSet
  SUBROUTINE SOLVER_NEWTON_JACOBIAN_CALCULATION_TYPE_SET(SOLVER,JACOBIAN_CALCULATION_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the Jacobian calculation type
    INTEGER(INTG), INTENT(IN) :: JACOBIAN_CALCULATION_TYPE !<The type of Jacobian calculation type to set \see SOLVER_ROUTINES_JacobianCalculationTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_JACOBIAN_CALCULATION_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(JACOBIAN_CALCULATION_TYPE/=NEWTON_SOLVER%JACOBIAN_CALCULATION_TYPE) THEN
                  SELECT CASE(JACOBIAN_CALCULATION_TYPE)
                  CASE(SOLVER_NEWTON_JACOBIAN_NOT_CALCULATED)
                    NEWTON_SOLVER%JACOBIAN_CALCULATION_TYPE=SOLVER_NEWTON_JACOBIAN_NOT_CALCULATED
                  CASE(SOLVER_NEWTON_JACOBIAN_ANALTYIC_CALCULATED)
                    NEWTON_SOLVER%JACOBIAN_CALCULATION_TYPE=SOLVER_NEWTON_JACOBIAN_ANALTYIC_CALCULATED
                  CASE(SOLVER_NEWTON_JACOBIAN_FD_CALCULATED)
                    NEWTON_SOLVER%JACOBIAN_CALCULATION_TYPE=SOLVER_NEWTON_JACOBIAN_FD_CALCULATED
                  CASE DEFAULT
                    LOCAL_ERROR="The Jacobian calculation type of "// &
                      & TRIM(NUMBER_TO_VSTRING(JACOBIAN_CALCULATION_TYPE,"*",ERR,ERROR))//" is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT              
                ENDIF
              ELSE
                CALL FLAG_ERROR("The nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The Solver nonlinear solver is not associated",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_JACOBIAN_CALCULATION_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_JACOBIAN_CALCULATION_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_JACOBIAN_CALCULATION_TYPE_SET")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_JACOBIAN_CALCULATION_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for a Newton solver.
  SUBROUTINE SOLVER_NEWTON_LIBRARY_TYPE_GET(NEWTON_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER !<A pointer the Newton solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On exit, the type of library used for the Newton solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER
    TYPE(NEWTON_TRUSTREGION_SOLVER_TYPE), POINTER :: TRUSTREGION_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
 
    CALL ENTERS("SOLVER_NEWTON_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(NEWTON_SOLVER)) THEN
      SELECT CASE(NEWTON_SOLVER%NEWTON_SOLVE_TYPE)
      CASE(SOLVER_NEWTON_LINESEARCH)
        LINESEARCH_SOLVER=>NEWTON_SOLVER%LINESEARCH_SOLVER
        IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
          SOLVER_LIBRARY_TYPE=LINESEARCH_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("Newton line search solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_NEWTON_TRUSTREGION)
        TRUSTREGION_SOLVER=>NEWTON_SOLVER%TRUSTREGION_SOLVER
        IF(ASSOCIATED(TRUSTREGION_SOLVER)) THEN
          SOLVER_LIBRARY_TYPE=TRUSTREGION_SOLVER%SOLVER_LIBRARY
        ELSE
          CALL FLAG_ERROR("Newton trust region solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The Newton solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVER%NEWTON_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Newton solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library to use for a Newton solver.
  SUBROUTINE SOLVER_NEWTON_LIBRARY_TYPE_SET(NEWTON_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER !<A pointer the Newton solver to get the library type for.
    INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library for the optimiser solver to set. \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER
    TYPE(NEWTON_TRUSTREGION_SOLVER_TYPE), POINTER :: TRUSTREGION_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_NEWTON_LIBRARY_TYPE_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(NEWTON_SOLVER)) THEN
      SELECT CASE(NEWTON_SOLVER%NEWTON_SOLVE_TYPE)
      CASE(SOLVER_NEWTON_LINESEARCH)
        LINESEARCH_SOLVER=>NEWTON_SOLVER%LINESEARCH_SOLVER
        IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
          SELECT CASE(SOLVER_LIBRARY_TYPE)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            LINESEARCH_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
            LINESEARCH_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a Newton linesearch solver."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("Newton line search solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_NEWTON_TRUSTREGION)
        TRUSTREGION_SOLVER=>NEWTON_SOLVER%TRUSTREGION_SOLVER
        IF(ASSOCIATED(TRUSTREGION_SOLVER)) THEN
          SELECT CASE(SOLVER_LIBRARY_TYPE)
          CASE(SOLVER_CMISS_LIBRARY)
            CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
          CASE(SOLVER_PETSC_LIBRARY)
            TRUSTREGION_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
            TRUSTREGION_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
          CASE DEFAULT
            LOCAL_ERROR="The solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
              & " is invalid for a Newton trustregion solver."
            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
          END SELECT
        ELSE
          CALL FLAG_ERROR("Newton trust region solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The Newton solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVER%NEWTON_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Newton solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_NEWTON_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LIBRARY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_LIBRARY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Returns the linear solver associated with a Newton solver \todo should this be SOLVER_NONLINEAR_NEWTON_LINEAR_SOLVER_GET??? \see OPENCMISS::CMISSSolverNewtonLinearSolverGetSet
  SUBROUTINE SOLVER_NEWTON_LINEAR_SOLVER_GET(SOLVER,LINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the Newton solver to get the linear solver for
    TYPE(SOLVER_TYPE), POINTER :: LINEAR_SOLVER !<On exit, a pointer the linear solver linked to the Newton solver. Must not be associated on entry
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER

    CALL ENTERS("SOLVER_NEWTON_LINEAR_SOLVER_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(ASSOCIATED(LINEAR_SOLVER)) THEN
        CALL FLAG_ERROR("Linear solver is already associated.",ERR,ERROR,*999)
      ELSE
        NULLIFY(LINEAR_SOLVER)
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                LINEAR_SOLVER=>NEWTON_SOLVER%LINEAR_SOLVER
                IF(.NOT.ASSOCIATED(LINEAR_SOLVER)) &
                  & CALL FLAG_ERROR("Newton solver linear solver is not associated.",ERR,ERROR,*999)
              ELSE
                CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The specified solver is not a dynamic solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_LINEAR_SOLVER_GET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_LINEAR_SOLVER_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LINEAR_SOLVER_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_LINEAR_SOLVER_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the line search alpha for a Newton linesearch solver \todo should this be SOLVER_NONLINEAR_NEWTON_LINESEARCH_ALPHA_SET??? \see OPENCMISS::CMISSSolverNewtonLineSearchAlphaSet
  SUBROUTINE SOLVER_NEWTON_LINESEARCH_ALPHA_SET(SOLVER,LINESEARCH_ALPHA,ERR,ERROR,*)
    
    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the line search alpha for
    REAL(DP), INTENT(IN) :: LINESEARCH_ALPHA !<The line search alpha to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_LINESEARCH_ALPHA_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(NEWTON_SOLVER%NEWTON_SOLVE_TYPE==SOLVER_NEWTON_LINESEARCH) THEN
                  LINESEARCH_SOLVER=>NEWTON_SOLVER%LINESEARCH_SOLVER
                  IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
                    IF(LINESEARCH_ALPHA>ZERO_TOLERANCE) THEN
                      LINESEARCH_SOLVER%LINESEARCH_ALPHA=LINESEARCH_ALPHA
                    ELSE
                      LOCAL_ERROR="The specified line search alpha of "//TRIM(NUMBER_TO_VSTRING(LINESEARCH_ALPHA,"*",ERR,ERROR))// &
                        & " is invalid. The line search alpha must be > 0."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("The Newton solver line search solver is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("The Newton solver is not a line search solver.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_ALPHA_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_LINESEARCH_ALPHA_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_ALPHA_SET")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_LINESEARCH_ALPHA_SET
        
  !
  !================================================================================================================================
  !

  !>Finishes the process of creating nonlinear Newton line search solver
  SUBROUTINE SOLVER_NEWTON_LINESEARCH_CREATE_FINISH(LINESEARCH_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER !<A pointer the nonlinear Newton line search solver to finish the creation of
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    EXTERNAL :: SNESDefaultComputeJacobianColor
    EXTERNAL :: PROBLEM_SOLVER_JACOBIAN_EVALUATE_PETSC
    EXTERNAL :: PROBLEM_SOLVER_RESIDUAL_EVALUATE_PETSC
    EXTERNAL :: SOLVER_NONLINEAR_MONITOR_PETSC
    INTEGER(INTG) :: equations_matrix_idx,equations_set_idx
    TYPE(DISTRIBUTED_MATRIX_TYPE), POINTER :: JACOBIAN_MATRIX
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: RESIDUAL_VECTOR
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MAPPING_LINEAR_TYPE), POINTER :: LINEAR_MAPPING
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_LINEAR_TYPE), POINTER :: LINEAR_MATRICES
    TYPE(EQUATIONS_MATRIX_TYPE), POINTER :: EQUATIONS_MATRIX
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: LINEAR_VARIABLE
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(SOLVER_TYPE), POINTER :: LINEAR_SOLVER,SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(SOLVER_MATRIX_TYPE), POINTER :: SOLVER_JACOBIAN
    TYPE(VARYING_STRING) :: LOCAL_ERROR
  
    CALL ENTERS("SOLVER_NEWTON_LINESEARCH_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
      NEWTON_SOLVER=>LINESEARCH_SOLVER%NEWTON_SOLVER
      IF(ASSOCIATED(NEWTON_SOLVER)) THEN
        NONLINEAR_SOLVER=>NEWTON_SOLVER%NONLINEAR_SOLVER
        IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
          SOLVER=>NONLINEAR_SOLVER%SOLVER
          IF(ASSOCIATED(SOLVER)) THEN
            SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
            IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
              SELECT CASE(LINESEARCH_SOLVER%SOLVER_LIBRARY)
              CASE(SOLVER_CMISS_LIBRARY)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(SOLVER_PETSC_LIBRARY)
                SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
                IF(ASSOCIATED(SOLVER_MAPPING)) THEN
                  !Loop over the equations set in the solver equations
                  DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                    EQUATIONS=>SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)%EQUATIONS
                    IF(ASSOCIATED(EQUATIONS)) THEN
                      EQUATIONS_SET=>EQUATIONS%EQUATIONS_SET
                      IF(ASSOCIATED(EQUATIONS_SET)) THEN
                        DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                        IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                          EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                          IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                            LINEAR_MAPPING=>EQUATIONS_MAPPING%LINEAR_MAPPING
                            IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                              !If there are any linear matrices create temporary vector for matrix-vector products
                              EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                              IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                                LINEAR_MATRICES=>EQUATIONS_MATRICES%LINEAR_MATRICES
                                IF(ASSOCIATED(LINEAR_MATRICES)) THEN
                                  DO equations_matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                                    EQUATIONS_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_idx)%PTR
                                    IF(ASSOCIATED(EQUATIONS_MATRIX)) THEN
                                      IF(.NOT.ASSOCIATED(EQUATIONS_MATRIX%TEMP_VECTOR)) THEN
                                        LINEAR_VARIABLE=>LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)%VARIABLE
                                        IF(ASSOCIATED(LINEAR_VARIABLE)) THEN
                                          CALL DISTRIBUTED_VECTOR_CREATE_START(LINEAR_VARIABLE%DOMAIN_MAPPING, &
                                            & EQUATIONS_MATRIX%TEMP_VECTOR,ERR,ERROR,*999)
                                          CALL DISTRIBUTED_VECTOR_DATA_TYPE_SET(EQUATIONS_MATRIX%TEMP_VECTOR, &
                                            & DISTRIBUTED_MATRIX_VECTOR_DP_TYPE,ERR,ERROR,*999)
                                          CALL DISTRIBUTED_VECTOR_CREATE_FINISH(EQUATIONS_MATRIX%TEMP_VECTOR,ERR,ERROR,*999)
                                        ELSE
                                          CALL FLAG_ERROR("Linear mapping linear variable is not associated.",ERR,ERROR,*999)
                                        ENDIF
                                      ENDIF
                                    ELSE
                                      CALL FLAG_ERROR("Equations matrix is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ENDDO !equations_matrix_idx
                                ELSE
                                  CALL FLAG_ERROR("Equations matrices linear matrices is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                CALL FLAG_ERROR("Equations equations matrices is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("Equations equations mapping is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          LOCAL_ERROR="Equations set dependent field is not associated for equations set index "// &
                            & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        LOCAL_ERROR="Equations equations set is not associated for equations set index "// &
                          & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      LOCAL_ERROR="Equations is not associated for equations set index "// &
                        & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ENDDO !equations_set_idx
                  
                  !Create the PETSc SNES solver
                  CALL PETSC_SNESCREATE(COMPUTATIONAL_ENVIRONMENT%MPI_COMM,LINESEARCH_SOLVER%SNES,ERR,ERROR,*999)
                  !Set the nonlinear solver type to be a Newton line search solver
                  CALL PETSC_SNESSETTYPE(LINESEARCH_SOLVER%SNES,PETSC_SNESLS,ERR,ERROR,*999)
                  
                  !Create the solver matrices and vectors
                  LINEAR_SOLVER=>NEWTON_SOLVER%LINEAR_SOLVER
                  IF(ASSOCIATED(LINEAR_SOLVER)) THEN
                    NULLIFY(SOLVER_MATRICES)
                    CALL SOLVER_MATRICES_CREATE_START(SOLVER_EQUATIONS,SOLVER_MATRICES,ERR,ERROR,*999)
                    CALL SOLVER_MATRICES_LIBRARY_TYPE_SET(SOLVER_MATRICES,SOLVER_PETSC_LIBRARY,ERR,ERROR,*999)
                    SELECT CASE(SOLVER_EQUATIONS%SPARSITY_TYPE)
                    CASE(SOLVER_SPARSE_MATRICES)
                      CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_COMPRESSED_ROW_STORAGE_TYPE/), &
                        & ERR,ERROR,*999)
                    CASE(SOLVER_FULL_MATRICES)
                      CALL SOLVER_MATRICES_STORAGE_TYPE_SET(SOLVER_MATRICES,(/DISTRIBUTED_MATRIX_BLOCK_STORAGE_TYPE/), &
                        & ERR,ERROR,*999)
                    CASE DEFAULT
                      LOCAL_ERROR="The specified solver equations sparsity type of "// &
                        & TRIM(NUMBER_TO_VSTRING(SOLVER_EQUATIONS%SPARSITY_TYPE,"*",ERR,ERROR))//" is invalid."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    END SELECT
                    CALL SOLVER_MATRICES_CREATE_FINISH(SOLVER_MATRICES,ERR,ERROR,*999)
                    !Link linear solver
                    LINEAR_SOLVER%SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
                    !Finish the creation of the linear solver
                    CALL SOLVER_LINEAR_CREATE_FINISH(LINEAR_SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
                    !Associate linear solver's KSP to nonlinear solver's SNES
                    SELECT CASE(LINEAR_SOLVER%LINEAR_SOLVER%LINEAR_SOLVE_TYPE)
                    CASE(SOLVER_LINEAR_DIRECT_SOLVE_TYPE)
                      CALL PETSC_SNESSETKSP(linesearch_solver%snes,linear_solver%linear_solver%direct_solver%ksp,ERR,ERROR,*999)
                    CASE(SOLVER_LINEAR_ITERATIVE_SOLVE_TYPE)
                      CALL PETSC_SNESSETKSP(linesearch_solver%snes,linear_solver%linear_solver%iterative_solver%ksp,ERR,ERROR,*999)
                    END SELECT

                    !Set the nonlinear function
                    RESIDUAL_VECTOR=>SOLVER_MATRICES%RESIDUAL
                    IF(ASSOCIATED(RESIDUAL_VECTOR)) THEN
                      IF(ASSOCIATED(RESIDUAL_VECTOR%PETSC)) THEN
                        !Pass the linesearch solver object rather than the temporary solver
                        CALL PETSC_SNESSETFUNCTION(LINESEARCH_SOLVER%SNES,RESIDUAL_VECTOR%PETSC%VECTOR, &
                          & PROBLEM_SOLVER_RESIDUAL_EVALUATE_PETSC,LINESEARCH_SOLVER%NEWTON_SOLVER%NONLINEAR_SOLVER%SOLVER, &
                          & ERR,ERROR,*999)
                      ELSE
                        CALL FLAG_ERROR("The residual vector PETSc is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      CALL FLAG_ERROR("Solver matrices residual vector is not associated.",ERR,ERROR,*999)
                    ENDIF
                  
                    !Set the Jacobian
                    IF(SOLVER_MATRICES%NUMBER_OF_MATRICES==1) THEN
                      SOLVER_JACOBIAN=>SOLVER_MATRICES%MATRICES(1)%PTR
                      IF(ASSOCIATED(SOLVER_JACOBIAN)) THEN
                        JACOBIAN_MATRIX=>SOLVER_JACOBIAN%MATRIX
                        IF(ASSOCIATED(JACOBIAN_MATRIX)) THEN
                          IF(ASSOCIATED(JACOBIAN_MATRIX%PETSC)) THEN
                            SELECT CASE(NEWTON_SOLVER%JACOBIAN_CALCULATION_TYPE)
                            CASE(SOLVER_NEWTON_JACOBIAN_NOT_CALCULATED)
                              CALL FLAG_ERROR("Cannot have no Jacobian calculation for a PETSc nonlinear linesearch solver.", &
                                & ERR,ERROR,*999)
                            CASE(SOLVER_NEWTON_JACOBIAN_ANALTYIC_CALCULATED)
                              SOLVER_JACOBIAN%UPDATE_MATRIX=.TRUE. !CMISS will fill in the Jacobian values
                              !Pass the linesearch solver object rather than the temporary solver
                              CALL PETSC_SNESSETJACOBIAN(LINESEARCH_SOLVER%SNES,JACOBIAN_MATRIX%PETSC%MATRIX, &
                                & JACOBIAN_MATRIX%PETSC%MATRIX,PROBLEM_SOLVER_JACOBIAN_EVALUATE_PETSC, &
                                & LINESEARCH_SOLVER%NEWTON_SOLVER%NONLINEAR_SOLVER%SOLVER,ERR,ERROR,*999)
                            CASE(SOLVER_NEWTON_JACOBIAN_FD_CALCULATED)
                              SOLVER_JACOBIAN%UPDATE_MATRIX=.FALSE. !Petsc will fill in the Jacobian values
                              CALL DISTRIBUTED_MATRIX_FORM(JACOBIAN_MATRIX,ERR,ERROR,*999)
                              CALL PETSC_MATGETCOLORING(JACOBIAN_MATRIX%PETSC%MATRIX,PETSC_MATCOLORING_SL,LINESEARCH_SOLVER% &
                                & JACOBIAN_ISCOLORING,ERR,ERROR,*999)
                              !Pass the linesearch solver object rather than the temporary solver
                              CALL PETSC_MATFDCOLORINGCREATE(JACOBIAN_MATRIX%PETSC%MATRIX,LINESEARCH_SOLVER% &
                                & JACOBIAN_ISCOLORING,LINESEARCH_SOLVER%JACOBIAN_FDCOLORING,ERR,ERROR,*999)
                              CALL PETSC_ISCOLORINGDESTROY(LINESEARCH_SOLVER%JACOBIAN_ISCOLORING,ERR,ERROR,*999)
#if ( PETSC_VERSION_MAJOR == 3 )
                              CALL PETSC_MATFDCOLORINGSETFUNCTION(LINESEARCH_SOLVER%JACOBIAN_FDCOLORING, &
                                & PROBLEM_SOLVER_RESIDUAL_EVALUATE_PETSC,LINESEARCH_SOLVER%NEWTON_SOLVER%NONLINEAR_SOLVER%SOLVER, &
                                & ERR,ERROR,*999)
#else                              
                              CALL PETSC_MATFDCOLORINGSETFUNCTIONSNES(LINESEARCH_SOLVER%JACOBIAN_FDCOLORING, &
                                & PROBLEM_SOLVER_RESIDUAL_EVALUATE_PETSC,LINESEARCH_SOLVER%NEWTON_SOLVER%NONLINEAR_SOLVER%SOLVER, &
                                & ERR,ERROR,*999)
#endif
                              CALL PETSC_MATFDCOLORINGSETFROMOPTIONS(LINESEARCH_SOLVER%JACOBIAN_FDCOLORING,ERR,ERROR,*999)
                              CALL PETSC_SNESSETJACOBIAN(LINESEARCH_SOLVER%SNES,JACOBIAN_MATRIX%PETSC%MATRIX, &
                                & JACOBIAN_MATRIX%PETSC%MATRIX,SNESDefaultComputeJacobianColor,LINESEARCH_SOLVER% &
                                & JACOBIAN_FDCOLORING,ERR,ERROR,*999)
                            CASE DEFAULT
                              LOCAL_ERROR="The Jacobian calculation type of "// &
                                & TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVER%JACOBIAN_CALCULATION_TYPE,"*",ERR,ERROR))// &
                                & " is invalid."
                              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                            END SELECT
                          ELSE
                            CALL FLAG_ERROR("Jacobian matrix PETSc is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Solver Jacobian matrix is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        CALL FLAG_ERROR("The solver Jacobian is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      LOCAL_ERROR="Invalid number of solver matrices. The number of solver matrices is "// &
                        & TRIM(NUMBER_TO_VSTRING(SOLVER_MATRICES%NUMBER_OF_MATRICES,"*",ERR,ERROR))//" and it should be 1."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                    IF(SOLVER%OUTPUT_TYPE>=SOLVER_PROGRESS_OUTPUT) THEN
                      !Set the monitor
                      !Pass the linesearch solver object rather than the temporary solver
                      CALL PETSC_SNESMONITORSET(LINESEARCH_SOLVER%SNES,SOLVER_NONLINEAR_MONITOR_PETSC, &
                        & LINESEARCH_SOLVER%NEWTON_SOLVER%NONLINEAR_SOLVER%SOLVER,ERR,ERROR,*999)
                    ENDIF
                    !Set the line search type
                    SELECT CASE(LINESEARCH_SOLVER%LINESEARCH_TYPE)
                    CASE(SOLVER_NEWTON_LINESEARCH_NONORMS)
                      CALL PETSC_SNESLINESEARCHSET(LINESEARCH_SOLVER%SNES,PETSC_SNES_LINESEARCH_NONORMS,ERR,ERROR,*999)
                    CASE(SOLVER_NEWTON_LINESEARCH_NONE)
                      CALL PETSC_SNESLINESEARCHSET(LINESEARCH_SOLVER%SNES,PETSC_SNES_LINESEARCH_NO,ERR,ERROR,*999)
                    CASE(SOLVER_NEWTON_LINESEARCH_QUADRATIC)
                      CALL PETSC_SNESLINESEARCHSET(LINESEARCH_SOLVER%SNES,PETSC_SNES_LINESEARCH_QUADRATIC,ERR,ERROR,*999)
                    CASE(SOLVER_NEWTON_LINESEARCH_CUBIC)
                      CALL PETSC_SNESLINESEARCHSET(LINESEARCH_SOLVER%SNES,PETSC_SNES_LINESEARCH_CUBIC,ERR,ERROR,*999)
                    CASE DEFAULT
                      LOCAL_ERROR="The nonlinear Newton line search type of "// &
                        & TRIM(NUMBER_TO_VSTRING(LINESEARCH_SOLVER%LINESEARCH_TYPE,"*",ERR,ERROR))//" is invalid."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    END SELECT
                    !Set line search parameters
                    CALL PETSC_SNESLINESEARCHSETPARAMS(LINESEARCH_SOLVER%SNES,LINESEARCH_SOLVER%LINESEARCH_ALPHA, &
                      & LINESEARCH_SOLVER%LINESEARCH_MAXSTEP,LINESEARCH_SOLVER%LINESEARCH_STEPTOLERANCE, &
                      & ERR,ERROR,*999)
                    !Set the tolerances for the SNES solver
                    CALL PETSC_SNESSETTOLERANCES(LINESEARCH_SOLVER%SNES,NEWTON_SOLVER%ABSOLUTE_TOLERANCE, &
                      & NEWTON_SOLVER%RELATIVE_TOLERANCE,NEWTON_SOLVER%SOLUTION_TOLERANCE, &
                      & NEWTON_SOLVER%MAXIMUM_NUMBER_OF_ITERATIONS, &
                      & NEWTON_SOLVER%MAXIMUM_NUMBER_OF_FUNCTION_EVALUATIONS,ERR,ERROR,*999)            
                    !Set any further SNES options from the command line options
                    CALL PETSC_SNESSETFROMOPTIONS(LINESEARCH_SOLVER%SNES,ERR,ERROR,*999)
                  ELSE
                    CALL FLAG_ERROR("Newton linesearch solver linear solver is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("Solver equations solver mapping is not associated.",ERR,ERROR,*999)
                ENDIF
              CASE DEFAULT
                LOCAL_ERROR="The solver library type of "// &
                  & TRIM(NUMBER_TO_VSTRING(LINESEARCH_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))//" is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            ELSE
              CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Nonlinear solver solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Newton solver nonlinear solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Linesearch solver Newton solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Line search solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_LINESEARCH_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_CREATE_FINISH")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_LINESEARCH_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Finalise a nonlinear Newton line search solver and deallocate all memory
  SUBROUTINE SOLVER_NEWTON_LINESEARCH_FINALISE(LINESEARCH_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER !<A pointer the nonlinear Newton line search solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
  
    CALL ENTERS("SOLVER_NEWTON_LINESEARCH_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
      CALL PETSC_ISCOLORINGFINALISE(LINESEARCH_SOLVER%JACOBIAN_ISCOLORING,ERR,ERROR,*999)
      CALL PETSC_MATFDCOLORINGFINALISE(LINESEARCH_SOLVER%JACOBIAN_FDCOLORING,ERR,ERROR,*999)
      CALL PETSC_SNESFINALISE(LINESEARCH_SOLVER%SNES,ERR,ERROR,*999)
      DEALLOCATE(LINESEARCH_SOLVER)
    ENDIF
        
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_LINESEARCH_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_FINALISE")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_LINESEARCH_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a nonlinear Newton line search solver for a Newton solver
  SUBROUTINE SOLVER_NEWTON_LINESEARCH_INITIALISE(NEWTON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER !<A pointer the nonlinear Newton solver to initialise the Newton line search solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
  
    CALL ENTERS("SOLVER_NEWTON_LINESEARCH_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(NEWTON_SOLVER)) THEN
      IF(ASSOCIATED(NEWTON_SOLVER%LINESEARCH_SOLVER)) THEN
        CALL FLAG_ERROR("Netwon line search solver is already associated for this Newton solver.",ERR,ERROR,*998)
      ELSE
        !Allocate and initialise the Newton linesearch solver
        ALLOCATE(NEWTON_SOLVER%LINESEARCH_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate nonlinear solver Newton line search solver.",ERR,ERROR,*999)
        NEWTON_SOLVER%LINESEARCH_SOLVER%NEWTON_SOLVER=>NEWTON_SOLVER
        NEWTON_SOLVER%LINESEARCH_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
        NEWTON_SOLVER%LINESEARCH_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
        NEWTON_SOLVER%LINESEARCH_SOLVER%LINESEARCH_TYPE=SOLVER_NEWTON_LINESEARCH_CUBIC
        NEWTON_SOLVER%LINESEARCH_SOLVER%LINESEARCH_ALPHA=0.0001_DP
        NEWTON_SOLVER%LINESEARCH_SOLVER%LINESEARCH_MAXSTEP=1.0E8_DP
        NEWTON_SOLVER%LINESEARCH_SOLVER%LINESEARCH_STEPTOLERANCE=CONVERGENCE_TOLERANCE
        CALL PETSC_ISCOLORINGINITIALISE(NEWTON_SOLVER%LINESEARCH_SOLVER%JACOBIAN_ISCOLORING,ERR,ERROR,*999)
        CALL PETSC_MATFDCOLORINGINITIALISE(NEWTON_SOLVER%LINESEARCH_SOLVER%JACOBIAN_FDCOLORING,ERR,ERROR,*999)
        CALL PETSC_SNESINITIALISE(NEWTON_SOLVER%LINESEARCH_SOLVER%SNES,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Newton solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_INITIALISE")
    RETURN
999 CALL SOLVER_NEWTON_LINESEARCH_FINALISE(NEWTON_SOLVER%LINESEARCH_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_NEWTON_LINESEARCH_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_LINESEARCH_INITIALISE

  !
  !================================================================================================================================
  !

  !>Sets/changes the line search maximum step for a nonlinear Newton linesearch solver. \todo should this be SOLVER_NONLINEAR_NEWTON_LINESEARCH_MAXSTEP_SET??? \see OPENCMISS::CMISSSolverNewtonLineSearchMaxStepSet
  SUBROUTINE SOLVER_NEWTON_LINESEARCH_MAXSTEP_SET(SOLVER,LINESEARCH_MAXSTEP,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the line search maximum step for
    REAL(DP), INTENT(IN) :: LINESEARCH_MAXSTEP !<The line search maximum step to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_LINESEARCH_MAXSTEP_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(NEWTON_SOLVER%NEWTON_SOLVE_TYPE==SOLVER_NEWTON_LINESEARCH) THEN
                  LINESEARCH_SOLVER=>NEWTON_SOLVER%LINESEARCH_SOLVER
                  IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
                    IF(LINESEARCH_MAXSTEP>ZERO_TOLERANCE) THEN
                      LINESEARCH_SOLVER%LINESEARCH_MAXSTEP=LINESEARCH_MAXSTEP
                    ELSE
                      LOCAL_ERROR="The specified line search maximum step of "// &
                        & TRIM(NUMBER_TO_VSTRING(LINESEARCH_MAXSTEP,"*",ERR,ERROR))// &
                        & " is invalid. The line search maximum step must be > 0."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("The Newton solver line search solver is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("The Newton solver is not a line search solver.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_MAXSTEP_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_LINESEARCH_MAXSTEP_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_MAXSTEP_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_LINESEARCH_MAXSTEP_SET
        
  !
  !================================================================================================================================
  !

  !Solves a nonlinear Newton line search solver 
  SUBROUTINE SOLVER_NEWTON_LINESEARCH_SOLVE(LINESEARCH_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER !<A pointer to the nonlinear Newton line search solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: CONVERGED_REASON,NUMBER_ITERATIONS
    REAL(DP) :: FUNCTION_NORM
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: RHS_VECTOR,SOLVER_VECTOR
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_NEWTON_LINESEARCH_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
      NEWTON_SOLVER=>LINESEARCH_SOLVER%NEWTON_SOLVER
      IF(ASSOCIATED(NEWTON_SOLVER)) THEN
        NONLINEAR_SOLVER=>NEWTON_SOLVER%NONLINEAR_SOLVER
        IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
          SOLVER=>NONLINEAR_SOLVER%SOLVER
          IF(ASSOCIATED(SOLVER)) THEN
            SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
            IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
              SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
              IF(ASSOCIATED(SOLVER_MATRICES)) THEN
                IF(SOLVER_MATRICES%NUMBER_OF_MATRICES==1) THEN
                  RHS_VECTOR=>SOLVER_MATRICES%RHS_VECTOR
                  IF(ASSOCIATED(RHS_VECTOR)) THEN
                    SOLVER_VECTOR=>SOLVER_MATRICES%MATRICES(1)%PTR%SOLVER_VECTOR
                    IF(ASSOCIATED(SOLVER_VECTOR)) THEN
                      SELECT CASE(LINESEARCH_SOLVER%SOLVER_LIBRARY)
                      CASE(SOLVER_CMISS_LIBRARY)
                        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                      CASE(SOLVER_PETSC_LIBRARY)
                        SELECT CASE(NEWTON_SOLVER%SOLUTION_INITIALISE_TYPE)
                        CASE(SOLVER_SOLUTION_INITIALISE_ZERO)
                          !Zero the solution vector
                          CALL DISTRIBUTED_VECTOR_ALL_VALUES_SET(SOLVER_VECTOR,0.0_DP,ERR,ERROR,*999)
                        CASE(SOLVER_SOLUTION_INITIALISE_CURRENT_FIELD)
                          !Make sure the solver vector contains the current dependent field values
                          CALL SOLVER_SOLUTION_UPDATE(SOLVER,ERR,ERROR,*999)
                        CASE(SOLVER_SOLUTION_INITIALISE_NO_CHANGE)
                          !Do nothing
                        CASE DEFAULT
                          LOCAL_ERROR="The Newton solver solution initialise type of "// &
                            & TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVER%SOLUTION_INITIALISE_TYPE,"*",ERR,ERROR))// &
                            & " is invalid."
                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                        END SELECT
                        !Solve the nonlinear equations
                        CALL PETSC_SNESSOLVE(LINESEARCH_SOLVER%SNES,RHS_VECTOR%PETSC%VECTOR,SOLVER_VECTOR%PETSC%VECTOR, &
                          & ERR,ERROR,*999)
                        !Check for convergence
                        CALL PETSC_SNESGETCONVERGEDREASON(LINESEARCH_SOLVER%SNES,CONVERGED_REASON,ERR,ERROR,*999)
                        SELECT CASE(CONVERGED_REASON)
                        CASE(PETSC_SNES_DIVERGED_FUNCTION_COUNT)
                          CALL FLAG_WARNING("Nonlinear line search solver did not converge. PETSc diverged function count.", &
                            & ERR,ERROR,*999)
                        CASE(PETSC_SNES_DIVERGED_LINEAR_SOLVE)
                          CALL FLAG_WARNING("Nonlinear line search solver did not converge. PETSc diverged linear solve.", &
                            & ERR,ERROR,*999)
                        CASE(PETSC_SNES_DIVERGED_FNORM_NAN)
                          CALL FLAG_WARNING("Nonlinear line search solver did not converge. PETSc diverged F Norm NaN.", &
                            & ERR,ERROR,*999)
                        CASE(PETSC_SNES_DIVERGED_MAX_IT)
                          CALL FLAG_WARNING("Nonlinear line search solver did not converge. PETSc diverged maximum iterations.", &
                            & ERR,ERROR,*999)
                        CASE(PETSC_SNES_DIVERGED_LS_FAILURE)
                          CALL FLAG_WARNING("Nonlinear line search solver did not converge. PETSc diverged line search failure.", &
                            & ERR,ERROR,*999)
                        CASE(PETSC_SNES_DIVERGED_LOCAL_MIN)
                          CALL FLAG_WARNING("Nonlinear line search solver did not converge. PETSc diverged local minimum.", &
                            & ERR,ERROR,*999)
                        END SELECT
                        IF(SOLVER%OUTPUT_TYPE>=SOLVER_SOLVER_OUTPUT) THEN
                          !Output solution characteristics
                          CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Newton linesearch solver parameters:",ERR,ERROR,*999)
                          CALL PETSC_SNESGETITERATIONNUMBER(LINESEARCH_SOLVER%SNES,NUMBER_ITERATIONS,ERR,ERROR,*999)
                          CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Final number of iterations = ",NUMBER_ITERATIONS, &
                            & ERR,ERROR,*999)
                          CALL PETSC_SNESGETFUNCTIONNORM(LINESEARCH_SOLVER%SNES,FUNCTION_NORM,ERR,ERROR,*999)
                          CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Final function norm = ",FUNCTION_NORM, &
                            & ERR,ERROR,*999)
                          SELECT CASE(CONVERGED_REASON)
                          CASE(PETSC_SNES_CONVERGED_FNORM_ABS)
                            CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged F Norm absolute.", &
                              & ERR,ERROR,*999)
                          CASE(PETSC_SNES_CONVERGED_FNORM_RELATIVE)
                            CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged F Norm relative.", &
                              & ERR,ERROR,*999)
                          CASE(PETSC_SNES_CONVERGED_PNORM_RELATIVE)
                            CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged P Norm relative.", &
                              & ERR,ERROR,*999)
                          CASE(PETSC_SNES_CONVERGED_ITS)
                            CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged its.",ERR,ERROR,*999)
                          CASE(PETSC_SNES_CONVERGED_ITERATING)
                            CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Converged Reason = PETSc converged iterating.",ERR,ERROR,*999)
                          END SELECT
                        ENDIF
                      CASE DEFAULT
                        LOCAL_ERROR="The Newton line search solver library type of "// &
                          & TRIM(NUMBER_TO_VSTRING(LINESEARCH_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))//" is invalid."
                        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                      END SELECT
                    ELSE
                      CALL FLAG_ERROR("Solver vector is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("Solver RHS vector is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  LOCAL_ERROR="The number of solver matrices of "// &
                    & TRIM(NUMBER_TO_VSTRING(SOLVER_MATRICES%NUMBER_OF_MATRICES,"*",ERR,ERROR))// &
                    & " is invalid. There should only be one solver matrix for a Newton linesearch solver."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("Solver matrices is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Nonlinear solver solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Newton solver nonlinear solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Linesearch solver Newton solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Linesearch solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_LINESEARCH_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_LINESEARCH_SOLVE
  
  !
  !================================================================================================================================
  !

  !>Sets/changes the line search step tolerance for a nonlinear Newton line search solver. \todo should this be SOLVER_NONLINEAR_NEWTON_LINESEARCH_STEPTOL_SET??? \see OPENCMISS::CMISSSolverNewtonLineSearchStepTolSet
  SUBROUTINE SOLVER_NEWTON_LINESEARCH_STEPTOL_SET(SOLVER,LINESEARCH_STEPTOL,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the line search step tolerance for
    REAL(DP), INTENT(IN) :: LINESEARCH_STEPTOL !<The line search step tolerance to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_LINESEARCH_STEPTOL_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(NEWTON_SOLVER%NEWTON_SOLVE_TYPE==SOLVER_NEWTON_LINESEARCH) THEN
                  LINESEARCH_SOLVER=>NEWTON_SOLVER%LINESEARCH_SOLVER
                  IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
                    IF(LINESEARCH_STEPTOL>ZERO_TOLERANCE) THEN
                      LINESEARCH_SOLVER%LINESEARCH_STEPTOLERANCE=LINESEARCH_STEPTOL
                    ELSE
                      LOCAL_ERROR="The specified line search step tolerance of "// &
                        & TRIM(NUMBER_TO_VSTRING(LINESEARCH_STEPTOL,"*",ERR,ERROR))// &
                        & " is invalid. The line search step tolerance must be > 0."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("The Newton solver line search solver is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("The Newton solver is not a line search solver.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The nonlinear Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_STEPTOL_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_LINESEARCH_STEPTOL_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_STEPTOL_SET")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_LINESEARCH_STEPTOL_SET
  
  !
  !================================================================================================================================
  !

  !>Sets/changes the line search type for a nonlinear Newton linesearch solver \todo should this be SOLVER_NONLINEAR_NEWTON_LINESEARCH_TYPE_SET??? \see OPENCMISS::CMISSSolverNewtonLineSearchTypeSet
  SUBROUTINE SOLVER_NEWTON_LINESEARCH_TYPE_SET(SOLVER,LINESEARCH_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the line search type for
    INTEGER(INTG), INTENT(IN) :: LINESEARCH_TYPE !<The line search type to set \see SOLVER_ROUTINES_NewtonLineSearchTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_LINESEARCH_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NEWTON_LINESEARCH) THEN
                  LINESEARCH_SOLVER=>NEWTON_SOLVER%LINESEARCH_SOLVER
                  IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
                    SELECT CASE(LINESEARCH_TYPE)
                    CASE(SOLVER_NEWTON_LINESEARCH_NONORMS)
                      LINESEARCH_SOLVER%LINESEARCH_TYPE=SOLVER_NEWTON_LINESEARCH_NONORMS
                    CASE(SOLVER_NEWTON_LINESEARCH_NONE)
                      LINESEARCH_SOLVER%LINESEARCH_TYPE=SOLVER_NEWTON_LINESEARCH_NONE
                    CASE(SOLVER_NEWTON_LINESEARCH_QUADRATIC)
                      LINESEARCH_SOLVER%LINESEARCH_TYPE=SOLVER_NEWTON_LINESEARCH_QUADRATIC
                    CASE(SOLVER_NEWTON_LINESEARCH_CUBIC)
                      LINESEARCH_SOLVER%LINESEARCH_TYPE=SOLVER_NEWTON_LINESEARCH_CUBIC
                    CASE DEFAULT
                      LOCAL_ERROR="The specified line search type of "//TRIM(NUMBER_TO_VSTRING(LINESEARCH_TYPE,"*",ERR,ERROR))// &
                        & " is invalid."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    END SELECT
                  ELSE
                    CALL FLAG_ERROR("The Newton solver line search solver is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("The Newton solver is not a line search solver.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_LINESEARCH_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_LINESEARCH_TYPE_SET")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_LINESEARCH_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for a Newton solver matrices.
  SUBROUTINE SOLVER_NEWTON_MATRICES_LIBRARY_TYPE_GET(NEWTON_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER !<A pointer the Newton solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: MATRICES_LIBRARY_TYPE !<On exit, the type of library used for the Newton solver matrices \see DISTRIBUTED_MATRIX_VECTOR_LibraryTypes,DISTRIBUTED_MATRIX_VECTOR
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_LINESEARCH_SOLVER_TYPE), POINTER :: LINESEARCH_SOLVER
    TYPE(NEWTON_TRUSTREGION_SOLVER_TYPE), POINTER :: TRUSTREGION_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
 
    CALL ENTERS("SOLVER_NEWTON_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(NEWTON_SOLVER)) THEN
      SELECT CASE(NEWTON_SOLVER%NEWTON_SOLVE_TYPE)
      CASE(SOLVER_NEWTON_LINESEARCH)
        LINESEARCH_SOLVER=>NEWTON_SOLVER%LINESEARCH_SOLVER
        IF(ASSOCIATED(LINESEARCH_SOLVER)) THEN
          MATRICES_LIBRARY_TYPE=LINESEARCH_SOLVER%SOLVER_MATRICES_LIBRARY
        ELSE
          CALL FLAG_ERROR("Newton line search solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_NEWTON_TRUSTREGION)
        TRUSTREGION_SOLVER=>NEWTON_SOLVER%TRUSTREGION_SOLVER
        IF(ASSOCIATED(TRUSTREGION_SOLVER)) THEN
          MATRICES_LIBRARY_TYPE=TRUSTREGION_SOLVER%SOLVER_MATRICES_LIBRARY
        ELSE
          CALL FLAG_ERROR("Newton trust region solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE DEFAULT
        LOCAL_ERROR="The Newton solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVER%NEWTON_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Newton solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_MATRICES_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_MATRICES_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_MATRICES_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the maximum number of function evaluations for a nonlinear Newton solver. \todo should this be SOLVER_NONLINEAR_NEWTON_MAXIMUM_FUNCTION_EVALUATIONS_SET??? \see OPENCMISS::CMISSSolverNewtonMaximumFunctionEvaluationsSet
  SUBROUTINE SOLVER_NEWTON_MAXIMUM_FUNCTION_EVALUATIONS_SET(SOLVER,MAXIMUM_FUNCTION_EVALUATIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the maximum function evaluations for
    INTEGER(INTG), INTENT(IN) :: MAXIMUM_FUNCTION_EVALUATIONS !<The maximum function evaluations to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_MAXIMUM_FUNCTION_EVALUATIONS_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(MAXIMUM_FUNCTION_EVALUATIONS>0) THEN
                  NEWTON_SOLVER%MAXIMUM_NUMBER_OF_FUNCTION_EVALUATIONS=MAXIMUM_FUNCTION_EVALUATIONS
                ELSE
                  LOCAL_ERROR="The specified maximum number of function evaluations of "// &
                    & TRIM(NUMBER_TO_VSTRING(MAXIMUM_FUNCTION_EVALUATIONS,"*",ERR,ERROR))// &
                    & " is invalid. The maximum number of function evaluations must be > 0."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_MAXIMUM_FUNCTION_EVALUATIONS_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_MAXIMUM_FUNCTION_EVALUATIONS_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_MAXIMUM_FUNCTION_EVALUATIONS_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_MAXIMUM_FUNCTION_EVALUATIONS_SET
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the maximum number of iterations for a nonlinear Newton solver. \todo should this be SOLVER_NONLINEAR_NEWTON_MAXIMUM_ITERATIONS_SET??? \see OPENCMISS::CMISSSolverNewtonMaximumIterationsSet
  SUBROUTINE SOLVER_NEWTON_MAXIMUM_ITERATIONS_SET(SOLVER,MAXIMUM_ITERATIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the maximum iterations for
    INTEGER(INTG), INTENT(IN) :: MAXIMUM_ITERATIONS !<The maximum iterations to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_MAXIMUM_ITERATIONS_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(MAXIMUM_ITERATIONS>0) THEN
                  NEWTON_SOLVER%MAXIMUM_NUMBER_OF_ITERATIONS=MAXIMUM_ITERATIONS
                ELSE
                  LOCAL_ERROR="The specified maximum iterations of "//TRIM(NUMBER_TO_VSTRING(MAXIMUM_ITERATIONS,"*",ERR,ERROR))// &
                    & " is invalid. The maximum number of iterations must be > 0."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("Nonlinear sovler Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_MAXIMUM_ITERATIONS_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_MAXIMUM_ITERATIONS_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_MAXIMUM_ITEATIONS_SET")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_MAXIMUM_ITERATIONS_SET
  
  !
  !================================================================================================================================
  !

  !>Sets/changes the relative tolerance for a nonlinear Newton solver. \todo should this be SOLVER_NONLINEAR_NEWTON_RELATIVE_TOLERANCE_SET??? \see OPENCMISS::CMISSSolverNewtonRelativeToleranceSet
  SUBROUTINE SOLVER_NEWTON_RELATIVE_TOLERANCE_SET(SOLVER,RELATIVE_TOLERANCE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the relative tolerance for
    REAL(DP), INTENT(IN) :: RELATIVE_TOLERANCE !<The relative tolerance to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_RELATIVE_TOLERANCE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(RELATIVE_TOLERANCE>ZERO_TOLERANCE) THEN
                  NEWTON_SOLVER%RELATIVE_TOLERANCE=RELATIVE_TOLERANCE
                ELSE
                  LOCAL_ERROR="The specified relative tolerance of "//TRIM(NUMBER_TO_VSTRING(RELATIVE_TOLERANCE,"*",ERR,ERROR))// &
                    & " is invalid. The relative tolerance must be > 0."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("The nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_RELATIVE_TOLERANCE_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_RELATIVE_TOLERANCE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_RELATIVE_TOLERANCE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_RELATIVE_TOLERANCE_SET
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the solution initialisation for a nonlinear Newton solver
  SUBROUTINE SOLVER_NEWTON_SOLUTION_INIT_TYPE_SET(SOLVER,SOLUTION_INITIALISE_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the solution tolerance for
    INTEGER(INTG), INTENT(IN) :: SOLUTION_INITIALISE_TYPE !<The solution initialise type to set \see SOLVER_ROUTINES_SolutionInitialiseTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_SOLUTION_INIT_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                SELECT CASE(SOLUTION_INITIALISE_TYPE)
                CASE(SOLVER_SOLUTION_INITIALISE_ZERO)
                  NEWTON_SOLVER%SOLUTION_INITIALISE_TYPE=SOLVER_SOLUTION_INITIALISE_ZERO
                CASE(SOLVER_SOLUTION_INITIALISE_CURRENT_FIELD)
                  NEWTON_SOLVER%SOLUTION_INITIALISE_TYPE=SOLVER_SOLUTION_INITIALISE_CURRENT_FIELD
                CASE(SOLVER_SOLUTION_INITIALISE_NO_CHANGE)
                  NEWTON_SOLVER%SOLUTION_INITIALISE_TYPE=SOLVER_SOLUTION_INITIALISE_NO_CHANGE
                CASE DEFAULT
                  LOCAL_ERROR="The specified solution initialise type  of "// &
                    & TRIM(NUMBER_TO_VSTRING(SOLUTION_INITIALISE_TYPE,"*",ERR,ERROR))//" is invalid."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                END SELECT
              ELSE
                CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF            
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_SOLUTION_INIT_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_SOLUTION_INIT_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_SOLUTION_INIT_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_SOLUTION_INIT_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the solution tolerance for a nonlinear Newton solver. \todo should this be SOLVER_NONLINEAR_NEWTON_SOLUTION_TOLERANCE_SET??? \see OPENCMISS::CMISSSolverNewtonSolutionToleranceSet
  SUBROUTINE SOLVER_NEWTON_SOLUTION_TOLERANCE_SET(SOLVER,SOLUTION_TOLERANCE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the solution tolerance for
    REAL(DP), INTENT(IN) :: SOLUTION_TOLERANCE !<The solution tolerance to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_SOLUTION_TOLERANCE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(SOLUTION_TOLERANCE>ZERO_TOLERANCE) THEN
                  NEWTON_SOLVER%SOLUTION_TOLERANCE=SOLUTION_TOLERANCE
                ELSE
                  LOCAL_ERROR="The specified solution tolerance of "//TRIM(NUMBER_TO_VSTRING(SOLUTION_TOLERANCE,"*",ERR,ERROR))// &
                    & " is invalid. The relative tolerance must be > 0."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF            
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_SOLUTION_TOLERANCE_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_SOLUTION_TOLERANCE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_SOLUTION_TOLERANCE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_SOLUTION_TOLERANCE_SET
        
  !
  !================================================================================================================================
  !

  !Solves a nonlinear Newton solver 
  SUBROUTINE SOLVER_NEWTON_SOLVE(NEWTON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER !<A pointer to the nonlinear Newton solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_NEWTON_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(NEWTON_SOLVER)) THEN
      SELECT CASE(NEWTON_SOLVER%NEWTON_SOLVE_TYPE)
      CASE(SOLVER_NEWTON_LINESEARCH)
        CALL SOLVER_NEWTON_LINESEARCH_SOLVE(NEWTON_SOLVER%LINESEARCH_SOLVER,ERR,ERROR,*999)
      CASE(SOLVER_NEWTON_TRUSTREGION)
        CALL SOLVER_NEWTON_TRUSTREGION_SOLVE(NEWTON_SOLVER%TRUSTREGION_SOLVER,ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The nonlinear solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVER%NEWTON_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Newton solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_NEWTON_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_SOLVE")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_SOLVE
        
  !
  !================================================================================================================================
  !

  !>Finishes the process of creating nonlinear Newton trust region solver
  SUBROUTINE SOLVER_NEWTON_TRUSTREGION_CREATE_FINISH(TRUSTREGION_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_TRUSTREGION_SOLVER_TYPE), POINTER :: TRUSTREGION_SOLVER !<A pointer the nonlinear Newton trust region solver to finish the creation of
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    EXTERNAL :: PROBLEM_SOLVER_RESIDUAL_EVALUATE_PETSC
    INTEGER(INTG) :: equations_matrix_idx,equations_set_idx
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: RESIDUAL_VECTOR
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MAPPING_LINEAR_TYPE), POINTER :: LINEAR_MAPPING
    TYPE(EQUATIONS_MATRICES_TYPE), POINTER :: EQUATIONS_MATRICES
    TYPE(EQUATIONS_MATRICES_LINEAR_TYPE), POINTER :: LINEAR_MATRICES
    TYPE(EQUATIONS_MATRIX_TYPE), POINTER :: EQUATIONS_MATRIX
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: LINEAR_VARIABLE
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(VARYING_STRING) :: LOCAL_ERROR
  
    CALL ENTERS("SOLVER_NEWTON_TRUSTREGION_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(TRUSTREGION_SOLVER)) THEN
      NEWTON_SOLVER=>TRUSTREGION_SOLVER%NEWTON_SOLVER
      IF(ASSOCIATED(NEWTON_SOLVER)) THEN
        NONLINEAR_SOLVER=>NEWTON_SOLVER%NONLINEAR_SOLVER
        IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
          SOLVER=>NONLINEAR_SOLVER%SOLVER
          IF(ASSOCIATED(SOLVER)) THEN
            SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
            IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
              SELECT CASE(TRUSTREGION_SOLVER%SOLVER_LIBRARY)
              CASE(SOLVER_CMISS_LIBRARY)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(SOLVER_PETSC_LIBRARY)
                SOLVER_MAPPING=>SOLVER_EQUATIONS%SOLVER_MAPPING
                IF(ASSOCIATED(SOLVER_MAPPING)) THEN
                  !Loop over the equations set in the solver equations
                  DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                    EQUATIONS=>SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)%EQUATIONS
                    IF(ASSOCIATED(EQUATIONS)) THEN
                      EQUATIONS_SET=>EQUATIONS%EQUATIONS_SET
                      IF(ASSOCIATED(EQUATIONS_SET)) THEN
                        DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                        IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                          EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                          IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                            LINEAR_MAPPING=>EQUATIONS_MAPPING%LINEAR_MAPPING
                            IF(ASSOCIATED(LINEAR_MAPPING)) THEN
                              !If there are any linear matrices create temporary vector for matrix-vector products
                              EQUATIONS_MATRICES=>EQUATIONS%EQUATIONS_MATRICES
                              IF(ASSOCIATED(EQUATIONS_MATRICES)) THEN
                                LINEAR_MATRICES=>EQUATIONS_MATRICES%LINEAR_MATRICES
                                IF(ASSOCIATED(LINEAR_MATRICES)) THEN
                                  DO equations_matrix_idx=1,LINEAR_MATRICES%NUMBER_OF_LINEAR_MATRICES
                                    EQUATIONS_MATRIX=>LINEAR_MATRICES%MATRICES(equations_matrix_idx)%PTR
                                    IF(ASSOCIATED(EQUATIONS_MATRIX)) THEN
                                      IF(.NOT.ASSOCIATED(EQUATIONS_MATRIX%TEMP_VECTOR)) THEN
                                        LINEAR_VARIABLE=>LINEAR_MAPPING%EQUATIONS_MATRIX_TO_VAR_MAPS(equations_matrix_idx)%VARIABLE
                                        IF(ASSOCIATED(LINEAR_VARIABLE)) THEN
                                          CALL DISTRIBUTED_VECTOR_CREATE_START(LINEAR_VARIABLE%DOMAIN_MAPPING, &
                                            & EQUATIONS_MATRIX%TEMP_VECTOR,ERR,ERROR,*999)
                                          CALL DISTRIBUTED_VECTOR_DATA_TYPE_SET(EQUATIONS_MATRIX%TEMP_VECTOR, &
                                            & DISTRIBUTED_MATRIX_VECTOR_DP_TYPE,ERR,ERROR,*999)
                                          CALL DISTRIBUTED_VECTOR_CREATE_FINISH(EQUATIONS_MATRIX%TEMP_VECTOR,ERR,ERROR,*999)
                                        ELSE
                                          CALL FLAG_ERROR("Linear mapping linear variable is not associated.",ERR,ERROR,*999)
                                        ENDIF
                                      ENDIF
                                    ELSE
                                      CALL FLAG_ERROR("Equations matrix is not associated.",ERR,ERROR,*999)
                                    ENDIF
                                  ENDDO !equations_matrix_idx
                                ELSE
                                  CALL FLAG_ERROR("Equations matrices linear matrices is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                CALL FLAG_ERROR("Equations equations matrices is not associated.",ERR,ERROR,*999)
                              ENDIF
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("Equations equations mapping is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          LOCAL_ERROR="Equations set dependent field is not associated for equations set index "// &
                            & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                        ENDIF
                      ELSE
                        LOCAL_ERROR="Equations equations set is not associated for equations set index "// &
                          & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                      ENDIF
                    ELSE
                      LOCAL_ERROR="Equations is not associated for equations set index "// &
                        & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ENDDO !equations_set_idx
                  
                  !Create the solver matrices and vectors
                  CALL SOLVER_MATRICES_CREATE_START(SOLVER_EQUATIONS,SOLVER_MATRICES,ERR,ERROR,*999)
                  CALL SOLVER_MATRICES_LIBRARY_TYPE_SET(SOLVER_MATRICES,SOLVER_PETSC_LIBRARY,ERR,ERROR,*999)
!!TODO: set up the matrix structure if using an analytic Jacobian            
                  CALL SOLVER_MATRICES_CREATE_FINISH(SOLVER_MATRICES,ERR,ERROR,*999)
                  !Create the PETSc SNES solver
                  CALL PETSC_SNESCREATE(COMPUTATIONAL_ENVIRONMENT%MPI_COMM,TRUSTREGION_SOLVER%SNES,ERR,ERROR,*999)
                  !Set the nonlinear solver type to be a Newton trust region solver
                  CALL PETSC_SNESSETTYPE(TRUSTREGION_SOLVER%SNES,PETSC_SNESTR,ERR,ERROR,*999)
                  !Set the nonlinear function
                  RESIDUAL_VECTOR=>SOLVER_MATRICES%RESIDUAL
                  IF(ASSOCIATED(RESIDUAL_VECTOR)) THEN
                    IF(ASSOCIATED(RESIDUAL_VECTOR%PETSC)) THEN
                      CALL PETSC_SNESSETFUNCTION(TRUSTREGION_SOLVER%SNES,RESIDUAL_VECTOR%PETSC%VECTOR, &
                        & PROBLEM_SOLVER_RESIDUAL_EVALUATE_PETSC,SOLVER,ERR,ERROR,*999)
                      CALL FLAG_ERROR("The residual vector PETSc is not associated.",ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("Solver matrices residual vector is not associated.",ERR,ERROR,*999)
                  ENDIF
                  !Set the Jacobian if necessary
                  !Set the trust region delta ???
                  
                  !Set the trust region tolerance
                  CALL PETSC_SNESSETTRUSTREGIONTOLERANCE(TRUSTREGION_SOLVER%SNES,TRUSTREGION_SOLVER%TRUSTREGION_TOLERANCE, &
                    & ERR,ERROR,*999)
                  !Set the tolerances for the SNES solver
                  CALL PETSC_SNESSETTOLERANCES(TRUSTREGION_SOLVER%SNES,NEWTON_SOLVER%ABSOLUTE_TOLERANCE, &
                    & NEWTON_SOLVER%RELATIVE_TOLERANCE,NEWTON_SOLVER%SOLUTION_TOLERANCE, &
                    & NEWTON_SOLVER%MAXIMUM_NUMBER_OF_ITERATIONS,NEWTON_SOLVER%MAXIMUM_NUMBER_OF_FUNCTION_EVALUATIONS, &
                    & ERR,ERROR,*999)
                  !Set any further SNES options from the command line options
                  CALL PETSC_SNESSETFROMOPTIONS(TRUSTREGION_SOLVER%SNES,ERR,ERROR,*999)
                ELSE
                  CALL FLAG_ERROR("Solver equations solver mapping is not associated.",ERR,ERROR,*999)
                ENDIF
              CASE DEFAULT
                LOCAL_ERROR="The solver library type of "// &
                  & TRIM(NUMBER_TO_VSTRING(TRUSTREGION_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))//" is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            ELSE
              CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Nonlinear solver solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Newton solver nonlinear solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Trust region Newton solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Trust region solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_TRUSTREGION_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_CREATE_FINISH")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_TRUSTREGION_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Sets/changes the trust region delta0 for a nonlinear Newton trust region solver solver. \todo should this be SOLVER_NONLINEAR_NEWTON_TRUSTREGION_DELTA0_SET??? \see OPENCMISS::CMISSSolverNewtonTrustRegionDelta0Set
  SUBROUTINE SOLVER_NEWTON_TRUSTREGION_DELTA0_SET(SOLVER,TRUSTREGION_DELTA0,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the trust region delta0 for
    REAL(DP), INTENT(IN) :: TRUSTREGION_DELTA0 !<The trust region delta0 to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NEWTON_TRUSTREGION_SOLVER_TYPE), POINTER :: TRUSTREGION_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_TRUSTREGION_DELTA0_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(NEWTON_SOLVER%NEWTON_SOLVE_TYPE==SOLVER_NEWTON_TRUSTREGION) THEN
                  TRUSTREGION_SOLVER=>NEWTON_SOLVER%TRUSTREGION_SOLVER
                  IF(ASSOCIATED(TRUSTREGION_SOLVER)) THEN
                    IF(TRUSTREGION_DELTA0>ZERO_TOLERANCE) THEN
                      TRUSTREGION_SOLVER%TRUSTREGION_DELTA0=TRUSTREGION_DELTA0
                    ELSE
                      LOCAL_ERROR="The specified trust region delta0 of "// &
                        & TRIM(NUMBER_TO_VSTRING(TRUSTREGION_DELTA0,"*",ERR,ERROR))// &
                        & " is invalid. The trust region delta0 must be > 0."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("The Newton solver trust region solver is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("The Newton solver is not a trust region solver.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_DELTA0_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_TRUSTREGION_DELTA0_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_DELTA0_SET")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_TRUSTREGION_DELTA0_SET
        
  !
  !================================================================================================================================
  !
  
  !>Finalise a nonlinear Newton trust region solver and deallocate all memory
  SUBROUTINE SOLVER_NEWTON_TRUSTREGION_FINALISE(TRUSTREGION_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_TRUSTREGION_SOLVER_TYPE), POINTER :: TRUSTREGION_SOLVER !<A pointer the non linear trust region solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
  
    CALL ENTERS("SOLVER_NEWTON_TRUSTREGION_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(TRUSTREGION_SOLVER)) THEN      
      CALL PETSC_SNESFINALISE(TRUSTREGION_SOLVER%SNES,ERR,ERROR,*999)
      DEALLOCATE(TRUSTREGION_SOLVER)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_TRUSTREGION_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_FINALISE")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_TRUSTREGION_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a Newton trust region solver for a nonlinear solver
  SUBROUTINE SOLVER_NEWTON_TRUSTREGION_INITIALISE(NEWTON_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER !<A pointer the Newton solver to initialise the trust region solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
  
    CALL ENTERS("SOLVER_NEWTON_TRUSTREGION_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(NEWTON_SOLVER)) THEN
      IF(ASSOCIATED(NEWTON_SOLVER%TRUSTREGION_SOLVER)) THEN
        CALL FLAG_ERROR("Trust region solver is already associated for this nonlinear solver.",ERR,ERROR,*998)
      ELSE
        ALLOCATE(NEWTON_SOLVER%TRUSTREGION_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate Newton solver trust region solver.",ERR,ERROR,*999)
        NEWTON_SOLVER%TRUSTREGION_SOLVER%NEWTON_SOLVER=>NEWTON_SOLVER
        NEWTON_SOLVER%TRUSTREGION_SOLVER%SOLVER_LIBRARY=SOLVER_PETSC_LIBRARY
        NEWTON_SOLVER%TRUSTREGION_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
!!TODO: set this properly
        NEWTON_SOLVER%TRUSTREGION_SOLVER%TRUSTREGION_DELTA0=0.01_DP
        CALL PETSC_SNESINITIALISE(NEWTON_SOLVER%TRUSTREGION_SOLVER%SNES,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Newton solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_INITIALISE")
    RETURN
999 CALL SOLVER_NEWTON_TRUSTREGION_FINALISE(NEWTON_SOLVER%TRUSTREGION_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_NEWTON_TRUSTREGION_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWWTON_TRUSTREGION_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_TRUSTREGION_INITIALISE

  !
  !================================================================================================================================
  !

  !Solves a nonlinear Newton trust region solver 
  SUBROUTINE SOLVER_NEWTON_TRUSTREGION_SOLVE(TRUSTREGION_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NEWTON_TRUSTREGION_SOLVER_TYPE), POINTER :: TRUSTREGION_SOLVER !<A pointer to the nonlinear Newton trust region solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_NEWTON_TRUSTREGION_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(TRUSTREGION_SOLVER)) THEN
      NEWTON_SOLVER=>TRUSTREGION_SOLVER%NEWTON_SOLVER
      IF(ASSOCIATED(NEWTON_SOLVER)) THEN        
        NONLINEAR_SOLVER=>NEWTON_SOLVER%NONLINEAR_SOLVER
        IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
          SOLVER=>NONLINEAR_SOLVER%SOLVER
          IF(ASSOCIATED(SOLVER)) THEN
            SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
            IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
              SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
              IF(ASSOCIATED(SOLVER_MATRICES)) THEN            
                SELECT CASE(TRUSTREGION_SOLVER%SOLVER_LIBRARY)
                CASE(SOLVER_CMISS_LIBRARY)
                  CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
                CASE(SOLVER_PETSC_LIBRARY)
                  CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)              
                CASE DEFAULT
                  LOCAL_ERROR="The nonlinear Newton trust region solver library type of "// &
                    & TRIM(NUMBER_TO_VSTRING(TRUSTREGION_SOLVER%SOLVER_LIBRARY,"*",ERR,ERROR))//" is invalid."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                END SELECT
              ELSE
                CALL FLAG_ERROR("Solver matrices is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Nonlinear solver solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Newton solver nonlinear solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Trust region solver Newton solver is not associated.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Trust region solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_TRUSTREGION_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_SOLVE")
    RETURN 1
    
  END SUBROUTINE SOLVER_NEWTON_TRUSTREGION_SOLVE
  
  !
  !================================================================================================================================
  !

  !>Sets/changes the trust region tolerance for a nonlinear Newton trust region solver. \todo should this be SOLVER_NONLINEAR_NEWTON_TRUSTREGION_TOLERANCE_SET??? \see OPENCMISS::CMISSSolverNewtonTrustRegionToleranceSet
  SUBROUTINE SOLVER_NEWTON_TRUSTREGION_TOLERANCE_SET(SOLVER,TRUSTREGION_TOLERANCE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the trust region tolerance for
    REAL(DP), INTENT(IN) :: TRUSTREGION_TOLERANCE !<The trust region tolerance to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NEWTON_TRUSTREGION_SOLVER_TYPE), POINTER :: TRUSTREGION_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_TRUSTREGION_TOLERANCE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(NEWTON_SOLVER%NEWTON_SOLVE_TYPE==SOLVER_NEWTON_TRUSTREGION) THEN
                  TRUSTREGION_SOLVER=>NEWTON_SOLVER%TRUSTREGION_SOLVER
                  IF(ASSOCIATED(TRUSTREGION_SOLVER)) THEN
                    IF(TRUSTREGION_TOLERANCE>ZERO_TOLERANCE) THEN
                      TRUSTREGION_SOLVER%TRUSTREGION_TOLERANCE=TRUSTREGION_TOLERANCE
                    ELSE
                      LOCAL_ERROR="The specified trust region tolerance of "// &
                        & TRIM(NUMBER_TO_VSTRING(TRUSTREGION_TOLERANCE,"*",ERR,ERROR))// &
                        & " is invalid. The trust region tolerance must be > 0."
                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("The Newton solver trust region solver is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("The Newton solver is not a trust region solver.",ERR,ERROR,*999)
                ENDIF
              ELSE
                CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_TOLERANCE_SET")
    RETURN
999 CALL ERRORS("SOLVER_NEWTON_TRUSTREGION_TOLERANCE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_TRUSTREGION_TOLERANCE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_TRUSTREGION_TOLERANCE_SET
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the type of nonlinear Newton solver. \todo should this be SOLVER_NONLINEAR_NEWTON_TYPE_SET??? \see OPENCMISS::CMISSSolverNewtonTypeSet
  SUBROUTINE SOLVER_NEWTON_TYPE_SET(SOLVER,NEWTON_SOLVE_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the nonlinear Newton solver type
    INTEGER(INTG), INTENT(IN) :: NEWTON_SOLVE_TYPE !<The type of nonlinear solver to set \see SOLVER_ROUTINES_NewtonSolverTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NEWTON_TYPE_SET",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*998)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE==SOLVER_NONLINEAR_NEWTON) THEN
              NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
              IF(ASSOCIATED(NEWTON_SOLVER)) THEN
                IF(NEWTON_SOLVE_TYPE/=NEWTON_SOLVER%NEWTON_SOLVE_TYPE) THEN
                  !Intialise the new solver type
                  SELECT CASE(NEWTON_SOLVE_TYPE)
                  CASE(SOLVER_NEWTON_LINESEARCH)
                    CALL SOLVER_NEWTON_LINESEARCH_INITIALISE(NEWTON_SOLVER,ERR,ERROR,*999)
                  CASE(SOLVER_NEWTON_TRUSTREGION)
                    CALL SOLVER_NEWTON_TRUSTREGION_INITIALISE(NEWTON_SOLVER,ERR,ERROR,*999)
                  CASE DEFAULT
                    LOCAL_ERROR="The Newton solver type of "//TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVE_TYPE,"*",ERR,ERROR))// &
                      & " is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT
                  !Finalise the old solver type
                  SELECT CASE(NEWTON_SOLVER%NEWTON_SOLVE_TYPE)
                  CASE(SOLVER_NEWTON_LINESEARCH)
                    CALL SOLVER_NEWTON_LINESEARCH_FINALISE(NEWTON_SOLVER%LINESEARCH_SOLVER,ERR,ERROR,*999)
                  CASE(SOLVER_NEWTON_TRUSTREGION)
                    CALL SOLVER_NEWTON_TRUSTREGION_FINALISE(NEWTON_SOLVER%TRUSTREGION_SOLVER,ERR,ERROR,*999)
                  CASE DEFAULT
                    LOCAL_ERROR="The Newton solver type of "// &
                      & TRIM(NUMBER_TO_VSTRING(NEWTON_SOLVER%NEWTON_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                  END SELECT
                  NEWTON_SOLVER%NEWTON_SOLVE_TYPE=NEWTON_SOLVE_TYPE
                ENDIF
              ELSE
                CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*998)
              ENDIF
            ELSE
              CALL FLAG_ERROR("The nonlinear solver is not a Newton solver.",ERR,ERROR,*998)
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*998)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*998)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
    
    CALL EXITS("SOLVER_NEWTON_TYPE_SET")
    RETURN
999 SELECT CASE(NEWTON_SOLVE_TYPE)
    CASE(SOLVER_NEWTON_LINESEARCH)
      CALL SOLVER_NEWTON_LINESEARCH_FINALISE(NEWTON_SOLVER%LINESEARCH_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    CASE(SOLVER_NEWTON_TRUSTREGION)
      CALL SOLVER_NEWTON_TRUSTREGION_FINALISE(NEWTON_SOLVER%TRUSTREGION_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    END SELECT
998 CALL ERRORS("SOLVER_NEWTON_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NEWTON_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NEWTON_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Finishes the process of creating a nonlinear solver 
  SUBROUTINE SOLVER_NONLINEAR_CREATE_FINISH(NONLINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER !<A pointer to the nonlinear solver to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_NONLINEAR_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
      SELECT CASE(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE)
      CASE(SOLVER_NONLINEAR_NEWTON)
        CALL SOLVER_NEWTON_CREATE_FINISH(NONLINEAR_SOLVER%NEWTON_SOLVER,ERR,ERROR,*999)
      CASE(SOLVER_NONLINEAR_BFGS_INVERSE)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_NONLINEAR_SQP)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The nonlinear solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Nonlinear solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_NONLINEAR_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_NONLINEAR_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_NONLINEAR_CREATE_FINISH")
    RETURN 1
   
  END SUBROUTINE SOLVER_NONLINEAR_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Finalise a nonlinear solver for a solver.
  SUBROUTINE SOLVER_NONLINEAR_FINALISE(NONLINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER !<A pointer the nonlinear solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_NONLINEAR_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
      CALL SOLVER_NEWTON_FINALISE(NONLINEAR_SOLVER%NEWTON_SOLVER,ERR,ERROR,*999)
      DEALLOCATE(NONLINEAR_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_NONLINEAR_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_NONLINEAR_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_NONLINEAR_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_NONLINEAR_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise a nonlinear solver for a solver.
  SUBROUTINE SOLVER_NONLINEAR_INITIALISE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to initialise the nonlinear solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR
    
    CALL ENTERS("SOLVER_NONLINEAR_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(ASSOCIATED(SOLVER%NONLINEAR_SOLVER)) THEN
        CALL FLAG_ERROR("Nonlinear solver is already associated for this solver.",ERR,ERROR,*998)
      ELSE
        !Allocate and initialise a Nonlinear solver
        ALLOCATE(SOLVER%NONLINEAR_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver nonlinear solver.",ERR,ERROR,*999)
        SOLVER%NONLINEAR_SOLVER%SOLVER=>SOLVER
        NULLIFY(SOLVER%NONLINEAR_SOLVER%NEWTON_SOLVER)
        !Default to a nonlinear Newton solver
        SOLVER%NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE=SOLVER_NONLINEAR_NEWTON
        CALL SOLVER_NEWTON_INITIALISE(SOLVER%NONLINEAR_SOLVER,ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_NONLINEAR_INITIALISE")
    RETURN
999 CALL SOLVER_NONLINEAR_FINALISE(SOLVER%NONLINEAR_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_NONLINEAR_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_NONLINEAR_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_NONLINEAR_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for a nonlinear solver.
  SUBROUTINE SOLVER_NONLINEAR_LIBRARY_TYPE_GET(NONLINEAR_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER !<A pointer the nonlinear solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On exit, the type of library used for the nonlinear solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_NONLINEAR_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
      SELECT CASE(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE)
      CASE(SOLVER_NONLINEAR_NEWTON)
        NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
        IF(ASSOCIATED(NEWTON_SOLVER)) THEN
          CALL SOLVER_NEWTON_LIBRARY_TYPE_GET(NEWTON_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_NONLINEAR_BFGS_INVERSE)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_NONLINEAR_SQP)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The nonlinear solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Nonlinear solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NONLINEAR_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_NONLINEAR_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_NONLINEAR_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NONLINEAR_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library to use for a nonlinear solver.
  SUBROUTINE SOLVER_NONLINEAR_LIBRARY_TYPE_SET(NONLINEAR_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER !<A pointer the nonlinear solver to get the library type for.
    INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library for the nonlinear solver to set. \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR
 
    CALL ENTERS("SOLVER_NONLINEAR_LIBRARY_TYPE_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
      SELECT CASE(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE)
      CASE(SOLVER_NONLINEAR_NEWTON)
        NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
        IF(ASSOCIATED(NEWTON_SOLVER)) THEN
          CALL SOLVER_NEWTON_LIBRARY_TYPE_SET(NEWTON_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_NONLINEAR_BFGS_INVERSE)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_NONLINEAR_SQP)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The nonlinear solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Nonlinear solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NONLINEAR_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_NONLINEAR_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NONLINEAR_LIBRARY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NONLINEAR_LIBRARY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for a nonlinear solver matrices.
  SUBROUTINE SOLVER_NONLINEAR_MATRICES_LIBRARY_TYPE_GET(NONLINEAR_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER !<A pointer the nonlinear solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: MATRICES_LIBRARY_TYPE !<On exit, the type of library used for the nonlinear solver matrices \see DISTRIBUTED_MATRIX_VECTOR_LibraryTypes,DISTRIBUTED_MATRIX_VECTOR
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(NEWTON_SOLVER_TYPE), POINTER :: NEWTON_SOLVER
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_NONLINEAR_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
      SELECT CASE(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE)
      CASE(SOLVER_NONLINEAR_NEWTON)
        NEWTON_SOLVER=>NONLINEAR_SOLVER%NEWTON_SOLVER
        IF(ASSOCIATED(NEWTON_SOLVER)) THEN
          CALL SOLVER_NEWTON_MATRICES_LIBRARY_TYPE_GET(NEWTON_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*999)
        ELSE
          CALL FLAG_ERROR("Nonlinear solver Newton solver is not associated.",ERR,ERROR,*999)
        ENDIF
      CASE(SOLVER_NONLINEAR_BFGS_INVERSE)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_NONLINEAR_SQP)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The nonlinear solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Nonlinear solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_NONLINEAR_MATRICES_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_NONLINEAR_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_NONLINEAR_MATRICES_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NONLINEAR_MATRICES_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Monitors the nonlinear solve.
  SUBROUTINE SOLVER_NONLINEAR_MONITOR(NONLINEAR_SOLVER,ITS,NORM,ERR,ERROR,*)

   !Argument variables
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER !<A pointer to the nonlinear solver to monitor
    INTEGER(INTG), INTENT(IN) :: ITS !<The number of iterations
    REAL(DP), INTENT(IN) :: NORM !<The residual norm
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    
    CALL ENTERS("SOLVER_NONLINEAR_MONITOR",ERR,ERROR,*999)

    IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
        
      CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
      CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
      CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"Nonlinear solve monitor: ",ERR,ERROR,*999)
      CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Iteration number = ",ITS,ERR,ERROR,*999)
      CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"  Function Norm    = ",NORM,ERR,ERROR,*999)
      !CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"    Number of function evaluations = ",NONLINEAR_SOLVER% &
      !  & TOTAL_NUMBER_OF_FUNCTION_EVALUATIONS,ERR,ERROR,*999)
      !CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"    Number of Jacobian evaluations = ",NONLINEAR_SOLVER% &
      !  & TOTAL_NUMBER_OF_JACOBIAN_EVALUATIONS,ERR,ERROR,*999)            
      CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"",ERR,ERROR,*999)      
        
    ELSE
      CALL FLAG_ERROR("Nonlinear solver is not associated.",ERR,ERROR,*999)
    ENDIF
     
    CALL EXITS("SOLVER_NONLINEAR_MONITOR")
    RETURN
999 CALL ERRORS("SOLVER_NONLINEAR_MONITOR",ERR,ERROR)
    CALL EXITS("SOLVER_NONLINEAR_MONITOR")
    RETURN 1
  END SUBROUTINE SOLVER_NONLINEAR_MONITOR

  !
  !================================================================================================================================
  !

  !Solves a nonlinear solver 
  SUBROUTINE SOLVER_NONLINEAR_SOLVE(NONLINEAR_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER !<A pointer to the nonlinear solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_NONLINEAR_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
      SELECT CASE(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE)
      CASE(SOLVER_NONLINEAR_NEWTON)
        CALL SOLVER_NEWTON_SOLVE(NONLINEAR_SOLVER%NEWTON_SOLVER,ERR,ERROR,*999)
      CASE(SOLVER_NONLINEAR_BFGS_INVERSE)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_NONLINEAR_SQP)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE DEFAULT
        LOCAL_ERROR="The nonlinear solver type of "// &
          & TRIM(NUMBER_TO_VSTRING(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Nonlinear solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_NONLINEAR_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_NONLINEAR_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_NONLINEAR_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_NONLINEAR_SOLVE
        
  !
  !================================================================================================================================
  !

  !>Sets/changes the type of nonlinear solver. \see OPENCMISS::CMISSSolverNonlinearTypeSet
  SUBROUTINE SOLVER_NONLINEAR_TYPE_SET(SOLVER,NONLINEAR_SOLVE_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the nonlinear solver type
    INTEGER(INTG), INTENT(IN) :: NONLINEAR_SOLVE_TYPE !<The type of nonlinear solver to set \see SOLVER_ROUTINES_NonlinearSolverTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR
    
    CALL ENTERS("SOLVER_NONLINEAR_TYPE_SET",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*998)
      ELSE
        IF(SOLVER%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
          NONLINEAR_SOLVER=>SOLVER%NONLINEAR_SOLVER
          IF(ASSOCIATED(NONLINEAR_SOLVER)) THEN
            IF(NONLINEAR_SOLVE_TYPE/=NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE) THEN
              !Intialise the new solver type
              SELECT CASE(NONLINEAR_SOLVE_TYPE)
              CASE(SOLVER_NONLINEAR_NEWTON)
                CALL SOLVER_NEWTON_INITIALISE(NONLINEAR_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_NONLINEAR_BFGS_INVERSE)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE(SOLVER_NONLINEAR_SQP)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The specified nonlinear solver type of "// &
                  & TRIM(NUMBER_TO_VSTRING(NONLINEAR_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
              !Finalise the old solver type
              SELECT CASE(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE)
              CASE(SOLVER_NONLINEAR_NEWTON)
                CALL SOLVER_NEWTON_FINALISE(NONLINEAR_SOLVER%NEWTON_SOLVER,ERR,ERROR,*999)
              CASE(SOLVER_NONLINEAR_BFGS_INVERSE)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)                
              CASE(SOLVER_NONLINEAR_SQP)
                CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
              CASE DEFAULT
                LOCAL_ERROR="The nonlinear solver type of "// &
                  & TRIM(NUMBER_TO_VSTRING(NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
              NONLINEAR_SOLVER%NONLINEAR_SOLVE_TYPE=NONLINEAR_SOLVE_TYPE
            ENDIF
          ELSE
            CALL FLAG_ERROR("The solver nonlinear solver is not associated.",ERR,ERROR,*998)
          ENDIF
        ELSE
          CALL FLAG_ERROR("The solver is not a nonlinear solver.",ERR,ERROR,*998)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
    
    CALL EXITS("SOLVER_NONLINEAR_TYPE_SET")
    RETURN
999 SELECT CASE(NONLINEAR_SOLVE_TYPE)
    CASE(SOLVER_NONLINEAR_NEWTON)
      CALL SOLVER_NEWTON_FINALISE(NONLINEAR_SOLVER%NEWTON_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    CASE(SOLVER_NONLINEAR_BFGS_INVERSE)
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*998)                
    CASE(SOLVER_NONLINEAR_SQP)
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*998)      
    END SELECT
998 CALL ERRORS("SOLVER_NONLINEAR_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_NONLINEAR_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_NONLINEAR_TYPE_SET
  
  !
  !================================================================================================================================
  !

  !>Finishes the process of creating an optimiser solver 
  SUBROUTINE SOLVER_OPTIMISER_CREATE_FINISH(OPTIMISER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(OPTIMISER_SOLVER_TYPE), POINTER :: OPTIMISER_SOLVER !<A pointer to the optimiser solver to finish the creation of.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_OPTIMISER_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(OPTIMISER_SOLVER)) THEN
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Optimiser solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_OPTIMISER_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVER_OPTIMISER_CREATE_FINISH",ERR,ERROR)    
    CALL EXITS("SOLVER_OPTIMISER_CREATE_FINISH")
    RETURN 1
   
  END SUBROUTINE SOLVER_OPTIMISER_CREATE_FINISH
        
  !
  !================================================================================================================================
  !

  !>Finalise a optimiser solver.
  SUBROUTINE SOLVER_OPTIMISER_FINALISE(OPTIMISER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(OPTIMISER_SOLVER_TYPE), POINTER :: OPTIMISER_SOLVER !<A pointer the optimiser solver to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_OPTIMISER_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(OPTIMISER_SOLVER)) THEN        
      DEALLOCATE(OPTIMISER_SOLVER)
    ENDIF
         
    CALL EXITS("SOLVER_OPTIMISER_FINALISE")
    RETURN
999 CALL ERRORS("SOLVER_OPTIMISER_FINALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_OPTIMISER_FINALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_OPTIMISER_FINALISE

  !
  !================================================================================================================================
  !

  !>Initialise an optimiser solver for a solver.
  SUBROUTINE SOLVER_OPTIMISER_INITIALISE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to initialise the optimiser solver for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    CALL ENTERS("SOLVER_OPTIMISER_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(ASSOCIATED(SOLVER%OPTIMISER_SOLVER)) THEN
        CALL FLAG_ERROR("Optimiser solver is already associated for this solver.",ERR,ERROR,*998)
      ELSE
        ALLOCATE(SOLVER%OPTIMISER_SOLVER,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solver optimiser solver.",ERR,ERROR,*999)
        SOLVER%OPTIMISER_SOLVER%SOLVER=>SOLVER
        SOLVER%OPTIMISER_SOLVER%SOLVER_LIBRARY=SOLVER_TAO_LIBRARY
        SOLVER%OPTIMISER_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
        
    CALL EXITS("SOLVER_OPTIMISER_INITIALISE")
    RETURN
999 CALL SOLVER_OPTIMISER_FINALISE(SOLVER%OPTIMISER_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_OPTIMISER_INITIALISE",ERR,ERROR)    
    CALL EXITS("SOLVER_OPTIMISER_INITIALISE")
    RETURN 1
   
  END SUBROUTINE SOLVER_OPTIMISER_INITIALISE

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for an optimiser solver.
  SUBROUTINE SOLVER_OPTIMISER_LIBRARY_TYPE_GET(OPTIMISER_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(OPTIMISER_SOLVER_TYPE), POINTER :: OPTIMISER_SOLVER !<A pointer the optimiser solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: SOLVER_LIBRARY_TYPE !<On exit, the type of library used for the optimiser solver \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
 
    CALL ENTERS("SOLVER_OPTIMISER_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(OPTIMISER_SOLVER)) THEN
      SOLVER_LIBRARY_TYPE=OPTIMISER_SOLVER%SOLVER_LIBRARY
    ELSE
      CALL FLAG_ERROR("Optimiser solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_OPTIMISER_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_OPTIMISER_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_OPTIMISER_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_OPTIMISER_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Sets/changes the type of library to use for an optimisation solver.
  SUBROUTINE SOLVER_OPTIMISER_LIBRARY_TYPE_SET(OPTIMISER_SOLVER,SOLVER_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(OPTIMISER_SOLVER_TYPE), POINTER :: OPTIMISER_SOLVER !<A pointer the optimiser solver to get the library type for.
    INTEGER(INTG), INTENT(IN) :: SOLVER_LIBRARY_TYPE !<The type of library for the optimiser solver to set. \see SOLVER_ROUTINES_SolverLibraries,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_OPTIMISER_LIBRARY_TYPE_SET",ERR,ERROR,*999)
    
    IF(ASSOCIATED(OPTIMISER_SOLVER)) THEN
      SELECT CASE(SOLVER_LIBRARY_TYPE)
      CASE(SOLVER_CMISS_LIBRARY)
        CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
      CASE(SOLVER_TAO_LIBRARY)
        OPTIMISER_SOLVER%SOLVER_LIBRARY=SOLVER_TAO_LIBRARY
        OPTIMISER_SOLVER%SOLVER_MATRICES_LIBRARY=DISTRIBUTED_MATRIX_VECTOR_PETSC_TYPE
      CASE DEFAULT
        LOCAL_ERROR="The specified solver library type of "//TRIM(NUMBER_TO_VSTRING(SOLVER_LIBRARY_TYPE,"*",ERR,ERROR))// &
          & " is invalid for an optimiser solver."
        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
      END SELECT
    ELSE
      CALL FLAG_ERROR("Optimiser solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_OPTIMISER_LIBRARY_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_OPTIMISER_LIBRARY_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_OPTIMISER_LIBRARY_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_OPTIMISER_LIBRARY_TYPE_SET

  !
  !================================================================================================================================
  !

  !>Returns the type of library to use for an optimiser solver matrices.
  SUBROUTINE SOLVER_OPTIMISER_MATRICES_LIBRARY_TYPE_GET(OPTIMISER_SOLVER,MATRICES_LIBRARY_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(OPTIMISER_SOLVER_TYPE), POINTER :: OPTIMISER_SOLVER !<A pointer the optimiser solver to get the library type for.
    INTEGER(INTG), INTENT(OUT) :: MATRICES_LIBRARY_TYPE !<On exit, the type of library used for the optimiser solver matrices \see DISTRIBUTED_MATRIX_VECTOR_LibraryTypes,DISTRIBUTED_MATRIX_VECTOR
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
 
    CALL ENTERS("SOLVER_OPTIMISER_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR,*999)

    IF(ASSOCIATED(OPTIMISER_SOLVER)) THEN
      MATRICES_LIBRARY_TYPE=OPTIMISER_SOLVER%SOLVER_MATRICES_LIBRARY
    ELSE
      CALL FLAG_ERROR("Optimiser solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_OPTIMISER_MATRICES_LIBRARY_TYPE_GET")
    RETURN
999 CALL ERRORS("SOLVER_OPTIMISER_MATRICES_LIBRARY_TYPE_GET",ERR,ERROR)    
    CALL EXITS("SOLVER_OPTIMISER_MATRICES_LIBRARY_TYPE_GET")
    RETURN 1
   
  END SUBROUTINE SOLVER_OPTIMISER_MATRICES_LIBRARY_TYPE_GET

  !
  !================================================================================================================================
  !

  !>Solve an optimiser solver
  SUBROUTINE SOLVER_OPTIMISER_SOLVE(OPTIMISER_SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(OPTIMISER_SOLVER_TYPE), POINTER :: OPTIMISER_SOLVER !<A pointer the optimiser solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVER_OPTIMISER_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(OPTIMISER_SOLVER)) THEN        
      CALL FLAG_ERROR("Not implemented.",ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Optimiser solver is not associated.",ERR,ERROR,*999)
    ENDIF
         
    CALL EXITS("SOLVER_OPTIMISER_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_OPTIMISER_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_OPTIMISER_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_OPTIMISER_SOLVE

  !
  !================================================================================================================================
  !

  !>Sets/changes the output type for a solver. \see OPENCMISS::CMISSSolverOutputTypeSet
  SUBROUTINE SOLVER_OUTPUT_TYPE_SET(SOLVER,OUTPUT_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the output type for
    INTEGER(INTG), INTENT(IN) :: OUTPUT_TYPE !<The type of solver output to be set \see SOLVER_ROUTINES_OutputTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
    
    CALL ENTERS("SOLVER_OUTPUT_TYPE_SET",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*999)
      ELSE        
        SELECT CASE(OUTPUT_TYPE)
        CASE(SOLVER_NO_OUTPUT)
          SOLVER%OUTPUT_TYPE=SOLVER_NO_OUTPUT
        CASE(SOLVER_PROGRESS_OUTPUT)
          SOLVER%OUTPUT_TYPE=SOLVER_PROGRESS_OUTPUT
        CASE(SOLVER_TIMING_OUTPUT)
          SOLVER%OUTPUT_TYPE=SOLVER_TIMING_OUTPUT
        CASE(SOLVER_SOLVER_OUTPUT)
          SOLVER%OUTPUT_TYPE=SOLVER_SOLVER_OUTPUT
        CASE(SOLVER_MATRIX_OUTPUT)
          SOLVER%OUTPUT_TYPE=SOLVER_MATRIX_OUTPUT         
        CASE DEFAULT
          LOCAL_ERROR="The specified solver output type of "// &
            & TRIM(NUMBER_TO_VSTRING(OUTPUT_TYPE,"*",ERR,ERROR))//" is invalid."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_OUTPUT_TYPE_SET")
    RETURN
999 CALL ERRORS("SOLVER_OUTPUT_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_OUTPUT_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_OUTPUT_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Updates the solver solution from the field variables
  SUBROUTINE SOLVER_SOLUTION_UPDATE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to update the solution from
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: column_number,equations_set_idx,local_number,solver_matrix_idx,variable_dof_idx,variable_idx,variable_type
    REAL(DP) :: additive_constant,VALUE,coupling_coefficient
    REAL(DP), POINTER :: VARIABLE_DATA(:)
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: SOLVER_VECTOR
    TYPE(DOMAIN_MAPPING_TYPE), POINTER :: DOMAIN_MAPPING
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: DEPENDENT_VARIABLE
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(SOLVER_MATRIX_TYPE), POINTER :: SOLVER_MATRIX
 
    NULLIFY(VARIABLE_DATA)
    
    CALL ENTERS("SOLVER_SOLUTION_UPDATE",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
        IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
          SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
          IF(ASSOCIATED(SOLVER_MATRICES)) THEN
            SOLVER_MAPPING=>SOLVER_MATRICES%SOLVER_MAPPING
            IF(ASSOCIATED(SOLVER_MAPPING)) THEN
              DO solver_matrix_idx=1,SOLVER_MATRICES%NUMBER_OF_MATRICES
                SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(solver_matrix_idx)%PTR
                IF(ASSOCIATED(SOLVER_MATRIX)) THEN
                  SOLVER_VECTOR=>SOLVER_MATRIX%SOLVER_VECTOR
                  IF(ASSOCIATED(SOLVER_VECTOR)) THEN
                    DOMAIN_MAPPING=>SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)%COLUMN_DOFS_MAPPING
                    IF(ASSOCIATED(DOMAIN_MAPPING)) THEN
                      DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                        DO variable_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                          & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%NUMBER_OF_VARIABLES
                          DEPENDENT_VARIABLE=>SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                            & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%VARIABLES(variable_idx)%PTR
                          IF(ASSOCIATED(DEPENDENT_VARIABLE)) THEN
                            variable_type=DEPENDENT_VARIABLE%VARIABLE_TYPE
                            DEPENDENT_FIELD=>DEPENDENT_VARIABLE%FIELD
                            CALL FIELD_PARAMETER_SET_DATA_GET(DEPENDENT_FIELD,variable_type,FIELD_VALUES_SET_TYPE,VARIABLE_DATA, &
                              & ERR,ERROR,*999)
                            DO variable_dof_idx=1,DEPENDENT_VARIABLE%NUMBER_OF_DOFS
                              column_number=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%VARIABLE_TO_SOLVER_COL_MAPS(variable_idx)% &
                                & COLUMN_NUMBERS(variable_dof_idx)
                              IF(column_number/=0) THEN
                                coupling_coefficient=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                  & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%VARIABLE_TO_SOLVER_COL_MAPS( &
                                  & variable_idx)%COUPLING_COEFFICIENTS(variable_dof_idx)
                                additive_constant=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                                  & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%VARIABLE_TO_SOLVER_COL_MAPS( &
                                  & variable_idx)%ADDITIVE_CONSTANTS(variable_dof_idx)
                                VALUE=VARIABLE_DATA(variable_dof_idx)*coupling_coefficient+additive_constant
                                local_number=DOMAIN_MAPPING%GLOBAL_TO_LOCAL_MAP(column_number)%LOCAL_NUMBER(1)
                                CALL DISTRIBUTED_VECTOR_VALUES_SET(SOLVER_VECTOR,local_number,VALUE,ERR,ERROR,*999)
                              ENDIF
                            ENDDO !variable_dof_idx
                            CALL FIELD_PARAMETER_SET_DATA_RESTORE(DEPENDENT_FIELD,variable_type,FIELD_VALUES_SET_TYPE, &
                              & VARIABLE_DATA,ERR,ERROR,*999)
                          ELSE
                            CALL FLAG_ERROR("Variable is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ENDDO !variable_idx
                      ENDDO !equations_set_idx
                    ELSE
                      CALL FLAG_ERROR("Domain mapping is not associated.",ERR,ERROR,*999)
                    ENDIF
                    CALL DISTRIBUTED_VECTOR_UPDATE_START(SOLVER_VECTOR,ERR,ERROR,*999)
                    CALL DISTRIBUTED_VECTOR_UPDATE_FINISH(SOLVER_VECTOR,ERR,ERROR,*999)
                  ELSE
                    CALL FLAG_ERROR("Solver vector is not associated.",ERR,ERROR,*999)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("Solver matrix is not associated.",ERR,ERROR,*999)
                ENDIF
              ENDDO !solver_matrix_idx
            ELSE
              CALL FLAG_ERROR("Solver matrices solution mapping is not associated.",ERR,ERROR,*999)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Solver equations solver matrices are not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVER_SOLUTION_UPDATE")
    RETURN
999 CALL ERRORS("SOLVER_SOLUTION_UPDATE",ERR,ERROR)    
    CALL EXITS("SOLVER_SOLUTION_UPDATE")
    RETURN 1
    
  END SUBROUTINE SOLVER_SOLUTION_UPDATE
  
  !
  !================================================================================================================================
  !

  !>Returns a pointer to the solver equations for a solver. \see OPENCMISS::CMISSSolverSolverEquationsGet
  SUBROUTINE SOLVER_SOLVER_EQUATIONS_GET(SOLVER,SOLVER_EQUATIONS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer to the solver to get the solver equations for
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS !<On exit, a pointer to the specified solver equations. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
 
    CALL ENTERS("SOLVER_SOLVER_EQUATIONS_GET",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN 
        IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
          CALL FLAG_ERROR("Solver equations is already associated.",ERR,ERROR,*998)
        ELSE
          SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
          IF(.NOT.ASSOCIATED(SOLVER_EQUATIONS)) CALL FLAG_ERROR("Solver equations is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver has not been finished.",ERR,ERROR,*998)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
       
    CALL EXITS("SOLVER_SOLVER_EQUATIONS_GET")
    RETURN
999 NULLIFY(SOLVER_EQUATIONS)
998 CALL ERRORS("SOLVER_SOLVER_EQUATIONS_GET",ERR,ERROR)
    CALL EXITS("SOLVER_SOLVER_EQUATIONS_GET")
    RETURN 1
    
  END SUBROUTINE SOLVER_SOLVER_EQUATIONS_GET
  
  !
  !================================================================================================================================
  !

  !>Solve the problem. 
  SUBROUTINE SOLVER_SOLVE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to solve
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    REAL(SP) :: SYSTEM_ELAPSED,SYSTEM_TIME1(1),SYSTEM_TIME2(1),USER_ELAPSED,USER_TIME1(1),USER_TIME2(1)
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVER_SOLVE",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
          CALL CPU_TIMER(USER_CPU,USER_TIME1,ERR,ERROR,*999)
          CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME1,ERR,ERROR,*999)          
        ENDIF
        !Solve the system depending on the solver type
        SELECT CASE(SOLVER%SOLVE_TYPE)
        CASE(SOLVER_LINEAR_TYPE)
          !Solve linear equations
          CALL SOLVER_LINEAR_SOLVE(SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
        CASE(SOLVER_NONLINEAR_TYPE)
          !Solve nonlinear equations
          CALL SOLVER_NONLINEAR_SOLVE(SOLVER%NONLINEAR_SOLVER,ERR,ERROR,*999)
        CASE(SOLVER_DYNAMIC_TYPE)
          !Solve dynamic equations
          CALL SOLVER_DYNAMIC_SOLVE(SOLVER%DYNAMIC_SOLVER,ERR,ERROR,*999)
        CASE(SOLVER_DAE_TYPE)
          !Solve differential-algebraic equations
          CALL SOLVER_DAE_SOLVE(SOLVER%DAE_SOLVER,ERR,ERROR,*999)
        CASE(SOLVER_EIGENPROBLEM_TYPE)
          !Solve eigenproblem
          CALL SOLVER_EIGENPROBLEM_SOLVE(SOLVER%EIGENPROBLEM_SOLVER,ERR,ERROR,*999)
        CASE DEFAULT
          LOCAL_ERROR="The solver type of "//TRIM(NUMBER_TO_VSTRING(SOLVER%SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        END SELECT
        !If necessary output the timing information
        IF(SOLVER%OUTPUT_TYPE>=SOLVER_TIMING_OUTPUT) THEN
          CALL CPU_TIMER(USER_CPU,USER_TIME2,ERR,ERROR,*999)
          CALL CPU_TIMER(SYSTEM_CPU,SYSTEM_TIME2,ERR,ERROR,*999)
          USER_ELAPSED=USER_TIME2(1)-USER_TIME1(1)
          SYSTEM_ELAPSED=SYSTEM_TIME2(1)-SYSTEM_TIME1(1)
          CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total user time for solve = ",USER_ELAPSED, &
            & ERR,ERROR,*999)
          CALL WRITE_STRING_VALUE(GENERAL_OUTPUT_TYPE,"Total System time for solve = ",SYSTEM_ELAPSED, &
            & ERR,ERROR,*999)
          CALL WRITE_STRING(GENERAL_OUTPUT_TYPE,"***",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
    ENDIF
        
    CALL EXITS("SOLVER_SOLVE")
    RETURN
999 CALL ERRORS("SOLVER_SOLVE",ERR,ERROR)    
    CALL EXITS("SOLVER_SOLVE")
    RETURN 1
   
  END SUBROUTINE SOLVER_SOLVE

  !
  !================================================================================================================================
  !

  !>Sets/changes the type for a solver.
  SUBROUTINE SOLVER_TYPE_SET(SOLVER,SOLVE_TYPE,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to set the solver type for.
    INTEGER(INTG), INTENT(IN) :: SOLVE_TYPE !<The type of solver to be set \see SOLVER_ROUTINES_SolverTypes,SOLVER_ROUTINES
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR
    
    CALL ENTERS("SOLVER_TYPE_SET",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        CALL FLAG_ERROR("Solver has already been finished.",ERR,ERROR,*998)
      ELSE
        IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
          CALL FLAG_ERROR("Can not changed the solver type for a solve that has been linked.",ERR,ERROR,*998)
        ELSE
          IF(SOLVE_TYPE/=SOLVER%SOLVE_TYPE) THEN
            !Initialise the new solver type 
            SELECT CASE(SOLVE_TYPE)
            CASE(SOLVER_LINEAR_TYPE)
              CALL SOLVER_LINEAR_INITIALISE(SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_NONLINEAR_TYPE)
              CALL SOLVER_NONLINEAR_INITIALISE(SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_TYPE)
              CALL SOLVER_DYNAMIC_INITIALISE(SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_DAE_TYPE)
              CALL SOLVER_DAE_INITIALISE(SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_EIGENPROBLEM_TYPE)
              CALL SOLVER_EIGENPROBLEM_INITIALISE(SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_OPTIMISER_TYPE)
              CALL SOLVER_OPTIMISER_INITIALISE(SOLVER,ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The specified solve type of "//TRIM(NUMBER_TO_VSTRING(SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
            !Finalise the old solve type
            SELECT CASE(SOLVER%SOLVE_TYPE)
            CASE(SOLVER_LINEAR_TYPE)
              CALL SOLVER_LINEAR_FINALISE(SOLVER%LINEAR_SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_NONLINEAR_TYPE)
              CALL SOLVER_NONLINEAR_FINALISE(SOLVER%NONLINEAR_SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_DYNAMIC_TYPE)
              CALL SOLVER_DYNAMIC_FINALISE(SOLVER%DYNAMIC_SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_DAE_TYPE)
              CALL SOLVER_DAE_FINALISE(SOLVER%DAE_SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_EIGENPROBLEM_TYPE)
              CALL SOLVER_EIGENPROBLEM_FINALISE(SOLVER%EIGENPROBLEM_SOLVER,ERR,ERROR,*999)
            CASE(SOLVER_OPTIMISER_TYPE)
              CALL SOLVER_OPTIMISER_FINALISE(SOLVER%OPTIMISER_SOLVER,ERR,ERROR,*999)
            CASE DEFAULT
              LOCAL_ERROR="The solver solve type of "//TRIM(NUMBER_TO_VSTRING(SOLVER%SOLVE_TYPE,"*",ERR,ERROR))//" is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
            !Set the solve type
            SOLVER%SOLVE_TYPE=SOLVE_TYPE
          ENDIF
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
    
    CALL EXITS("SOLVER_TYPE_SET")
    RETURN
999 SELECT CASE(SOLVE_TYPE)
    CASE(SOLVER_LINEAR_TYPE)
      CALL SOLVER_LINEAR_FINALISE(SOLVER%LINEAR_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    CASE(SOLVER_NONLINEAR_TYPE)
      CALL SOLVER_NONLINEAR_FINALISE(SOLVER%NONLINEAR_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    CASE(SOLVER_DYNAMIC_TYPE)
      CALL SOLVER_DYNAMIC_FINALISE(SOLVER%DYNAMIC_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    CASE(SOLVER_DAE_TYPE)
      CALL SOLVER_DAE_FINALISE(SOLVER%DAE_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    CASE(SOLVER_EIGENPROBLEM_TYPE)
      CALL SOLVER_EIGENPROBLEM_FINALISE(SOLVER%EIGENPROBLEM_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    CASE(SOLVER_OPTIMISER_TYPE)
      CALL SOLVER_OPTIMISER_FINALISE(SOLVER%OPTIMISER_SOLVER,DUMMY_ERR,DUMMY_ERROR,*998)
    END SELECT
998 CALL ERRORS("SOLVER_TYPE_SET",ERR,ERROR)    
    CALL EXITS("SOLVER_TYPE_SET")
    RETURN 1
   
  END SUBROUTINE SOLVER_TYPE_SET
        
  !
  !================================================================================================================================
  !

  !>Updates the dependent variables from the solver solution for dynamic solvers
  SUBROUTINE SOLVER_VARIABLES_DYNAMIC_FIELD_UPDATE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to update the variables from
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR,DYNAMIC_VARIABLE_TYPE,equations_set_idx,solver_dof_idx,solver_matrix_idx,variable_dof
    REAL(DP) :: ACCELERATION_VALUE,additive_constant,DELTA_T,DISPLACEMENT_VALUE,DYNAMIC_ACCELERATION_FACTOR, &
      & DYNAMIC_DISPLACEMENT_FACTOR,DYNAMIC_VELOCITY_FACTOR,SOLVER_VALUE,variable_coefficient,VELOCITY_VALUE,PREVIOUS_VALUE
    REAL(DP), POINTER :: SOLVER_DATA(:),PREVIOUS_DATA(:)
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: SOLVER_VECTOR
    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(EQUATIONS_MAPPING_DYNAMIC_TYPE), POINTER :: DYNAMIC_MAPPING
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: DEPENDENT_VARIABLE
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(SOLVER_MATRIX_TYPE), POINTER :: SOLVER_MATRIX
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR

    NULLIFY(SOLVER_DATA)
    
    CALL ENTERS("SOLVER_VARIABLES_DYNAMIC_FIELD_UPDATE",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        DYNAMIC_SOLVER=>SOLVER%DYNAMIC_SOLVER
        IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
          IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
            DELTA_T=DYNAMIC_SOLVER%TIME_INCREMENT
            SELECT CASE(DYNAMIC_SOLVER%DEGREE)
            CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
              DYNAMIC_DISPLACEMENT_FACTOR=DELTA_T
            CASE(SOLVER_DYNAMIC_SECOND_DEGREE)
              DYNAMIC_DISPLACEMENT_FACTOR=DELTA_T*DELTA_T/2.0_DP
              DYNAMIC_VELOCITY_FACTOR=DELTA_T
            CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
              DYNAMIC_DISPLACEMENT_FACTOR=DELTA_T*DELTA_T*DELTA_T/6.0_DP
              DYNAMIC_VELOCITY_FACTOR=DELTA_T*DELTA_T/2.0_DP
              DYNAMIC_ACCELERATION_FACTOR=DELTA_T            
            CASE DEFAULT
              LOCAL_ERROR="The dynamic solver degree of "//TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))// &
                & " is invalid."
              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
            END SELECT
          ENDIF
          SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
          IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
            SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
            IF(ASSOCIATED(SOLVER_MATRICES)) THEN
              SOLVER_MAPPING=>SOLVER_MATRICES%SOLVER_MAPPING
              IF(ASSOCIATED(SOLVER_MAPPING)) THEN            
                DO solver_matrix_idx=1,SOLVER_MATRICES%NUMBER_OF_MATRICES
                  SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(solver_matrix_idx)%PTR
                  IF(ASSOCIATED(SOLVER_MATRIX)) THEN
                    SOLVER_VECTOR=>SOLVER_MATRIX%SOLVER_VECTOR
                    IF(ASSOCIATED(SOLVER_VECTOR)) THEN
                      !Get the solver variables data                  
                      CALL DISTRIBUTED_VECTOR_DATA_GET(SOLVER_VECTOR,SOLVER_DATA,ERR,ERROR,*999)             
                      !Loop over the solver variable dofs
                      DO solver_dof_idx=1,SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)%NUMBER_OF_DOFS
                        !Loop over the equations sets associated with this dof
                        DO equations_set_idx=1,SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                          & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%NUMBER_OF_EQUATIONS_SETS                        
                          DEPENDENT_VARIABLE=>SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                            & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%VARIABLE(equations_set_idx)%PTR
                          IF(ASSOCIATED(DEPENDENT_VARIABLE)) THEN
                            DYNAMIC_VARIABLE_TYPE=DEPENDENT_VARIABLE%VARIABLE_TYPE
                            NULLIFY(DEPENDENT_FIELD)
                            DEPENDENT_FIELD=>DEPENDENT_VARIABLE%FIELD
                            IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                              !Get the dependent field dof the solver dof is mapped to
                              variable_dof=SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                                & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%VARIABLE_DOF(equations_set_idx)
                              variable_coefficient=SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                                & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%VARIABLE_COEFFICIENT(equations_set_idx)
                              additive_constant=SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                                & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%ADDITIVE_CONSTANT(equations_set_idx)
                              SOLVER_VALUE=SOLVER_DATA(solver_dof_idx)*variable_coefficient+additive_constant
                              !Set the dependent field dof
                              IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
                                NULLIFY(PREVIOUS_DATA)
                                !Use FIELD_PREVIOUS_VALUES_SET_TYPE to calculate updated dynamic solution
                                CALL FIELD_PARAMETER_SET_DATA_GET(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, & 
                                  & FIELD_PREVIOUS_VALUES_SET_TYPE,PREVIOUS_DATA,ERR,ERROR,*999)
                                PREVIOUS_VALUE=PREVIOUS_DATA(variable_dof)
                                CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_VALUES_SET_TYPE,variable_dof,PREVIOUS_VALUE,ERR,ERROR,*999)

                                DISPLACEMENT_VALUE=DYNAMIC_DISPLACEMENT_FACTOR*SOLVER_VALUE
                                CALL FIELD_PARAMETER_SET_ADD_LOCAL_DOF(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                  & FIELD_VALUES_SET_TYPE,variable_dof,DISPLACEMENT_VALUE,ERR,ERROR,*999)
                                IF(DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_FIRST_DEGREE) THEN
                                  VELOCITY_VALUE=DYNAMIC_VELOCITY_FACTOR*SOLVER_VALUE
                                  CALL FIELD_PARAMETER_SET_ADD_LOCAL_DOF(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                    & FIELD_VELOCITY_VALUES_SET_TYPE,variable_dof,VELOCITY_VALUE,ERR,ERROR,*999)
                                  IF(DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_SECOND_DEGREE) THEN
                                    ACCELERATION_VALUE=DYNAMIC_ACCELERATION_FACTOR*SOLVER_VALUE
                                    CALL FIELD_PARAMETER_SET_ADD_LOCAL_DOF(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & FIELD_ACCELERATION_VALUES_SET_TYPE,variable_dof,ACCELERATION_VALUE,ERR,ERROR,*999)
                                  ENDIF
                                ENDIF
                              ELSE
                                SELECT CASE(DYNAMIC_SOLVER%ORDER)
                                CASE(SOLVER_DYNAMIC_FIRST_ORDER)
                                  SELECT CASE(DYNAMIC_SOLVER%DEGREE)
                                  CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
                                    !Do nothing
                                  CASE(SOLVER_DYNAMIC_SECOND_DEGREE)                                  
                                    CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & FIELD_INITIAL_VELOCITY_SET_TYPE,variable_dof,SOLVER_VALUE,ERR,ERROR,*999)
                                  CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
                                    CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & FIELD_INITIAL_VELOCITY_SET_TYPE,variable_dof,SOLVER_VALUE,ERR,ERROR,*999)
                                    CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & FIELD_INITIAL_ACCELERATION_SET_TYPE,variable_dof,0.0_DP,ERR,ERROR,*999)
                                  CASE DEFAULT
                                    LOCAL_ERROR="The dynamic solver degree of "// &
                                      & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))//" is invalid."
                                    CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                                  END SELECT
                                CASE(SOLVER_DYNAMIC_SECOND_ORDER)
                                  IF(DYNAMIC_SOLVER%DEGREE==SOLVER_DYNAMIC_THIRD_DEGREE) THEN
                                    CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & FIELD_INITIAL_ACCELERATION_SET_TYPE,variable_dof,SOLVER_VALUE,ERR,ERROR,*999)
                                  ENDIF
                                CASE DEFAULT
                                  LOCAL_ERROR="The dynamic solver order of "// &
                                    & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%ORDER,"*",ERR,ERROR))//" is invalid."
                                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                                END SELECT
                              ENDIF
                            ELSE
                              CALL FLAG_ERROR("Dependent field is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("Dependent variable is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ENDDO !equations_set_idx
                      ENDDO !solver_dof_idx
                      !Restore the solver dof data
                      CALL DISTRIBUTED_VECTOR_DATA_RESTORE(SOLVER_VECTOR,SOLVER_DATA,ERR,ERROR,*999)
                      !Now store FIELD_PREVIOUS_VALUES_SET_TYPE so that state before changing BC is available
                      CALL FIELD_PARAMETER_SETS_COPY(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                        & FIELD_PREVIOUS_VALUES_SET_TYPE,1.0_DP,ERR,ERROR,*999)
                      !Start the transfer of the field dofs
                      DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                        EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                        IF(ASSOCIATED(EQUATIONS_SET)) THEN
                          DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                          IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                            EQUATIONS=>EQUATIONS_SET%EQUATIONS
                            IF(ASSOCIATED(EQUATIONS)) THEN
                              EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                              IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                                DYNAMIC_MAPPING=>EQUATIONS_MAPPING%DYNAMIC_MAPPING
                                IF(ASSOCIATED(DYNAMIC_MAPPING)) THEN
                                  DYNAMIC_VARIABLE_TYPE=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPE
                                  IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
                                    CALL FIELD_PARAMETER_SET_UPDATE_START(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
                                    IF(DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_FIRST_DEGREE) THEN
                                      CALL FIELD_PARAMETER_SET_UPDATE_START(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                        & FIELD_VELOCITY_VALUES_SET_TYPE,ERR,ERROR,*999)
                                      IF(DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_THIRD_DEGREE) THEN
                                        CALL FIELD_PARAMETER_SET_UPDATE_START(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                          & FIELD_ACCELERATION_VALUES_SET_TYPE,ERR,ERROR,*999)
                                      ENDIF
                                    ENDIF
                                  ELSE
                                    SELECT CASE(DYNAMIC_SOLVER%ORDER)
                                    CASE(SOLVER_DYNAMIC_FIRST_ORDER)
                                      SELECT CASE(DYNAMIC_SOLVER%DEGREE)
                                      CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
                                        !Do nothing
                                      CASE(SOLVER_DYNAMIC_SECOND_DEGREE)                                  
                                        CALL FIELD_PARAMETER_SET_UPDATE_START(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                          & FIELD_INITIAL_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                                      CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
                                        CALL FIELD_PARAMETER_SET_UPDATE_START(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                          & FIELD_INITIAL_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                                        CALL FIELD_PARAMETER_SET_UPDATE_START(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                          & FIELD_INITIAL_ACCELERATION_SET_TYPE,ERR,ERROR,*999)
                                      CASE DEFAULT
                                        LOCAL_ERROR="The dynamic solver degree of "// &
                                          & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))//" is invalid."
                                        CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                                      END SELECT
                                    CASE(SOLVER_DYNAMIC_SECOND_ORDER)
                                      IF(DYNAMIC_SOLVER%DEGREE==SOLVER_DYNAMIC_THIRD_DEGREE) THEN
                                        CALL FIELD_PARAMETER_SET_UPDATE_START(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                          & FIELD_INITIAL_ACCELERATION_SET_TYPE,ERR,ERROR,*999)
                                      ENDIF
                                    CASE DEFAULT
                                      LOCAL_ERROR="The dynamic solver order of "// &
                                        & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%ORDER,"*",ERR,ERROR))//" is invalid."
                                      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                                    END SELECT
                                  ENDIF
                                ELSE
                                  LOCAL_ERROR="Equations mapping dynamic mapping is not associated for equations set "// &
                                    & "index number "//TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                LOCAL_ERROR="Equations equations mapping is not associated for equations set index number "// &
                                  & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                                CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              LOCAL_ERROR="Equations set equations is not associated for equations set index number "// &
                                & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            LOCAL_ERROR="Equations set dependent field is not associated for equations set index number "// &
                              & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          LOCAL_ERROR="Equations set is not associated for equations set index number "// &
                            & TRIM(NUMBER_TO_VSTRING(equations_set_idx,"*",ERR,ERROR))//"."
                          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                        ENDIF
                      ENDDO !equations_set_idx
                      !Finish the transfer of the field dofs
                      DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                        EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                        DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                        EQUATIONS=>EQUATIONS_SET%EQUATIONS
                        EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                        DYNAMIC_MAPPING=>EQUATIONS_MAPPING%DYNAMIC_MAPPING
                        DYNAMIC_VARIABLE_TYPE=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPE
                        IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
                          CALL FIELD_PARAMETER_SET_UPDATE_FINISH(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                            & ERR,ERROR,*999)
                          IF(DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_FIRST_DEGREE) THEN
                            CALL FIELD_PARAMETER_SET_UPDATE_FINISH(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                              & FIELD_VELOCITY_VALUES_SET_TYPE,ERR,ERROR,*999)
                            IF(DYNAMIC_SOLVER%DEGREE>SOLVER_DYNAMIC_THIRD_DEGREE) THEN
                              CALL FIELD_PARAMETER_SET_UPDATE_FINISH(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                & FIELD_ACCELERATION_VALUES_SET_TYPE,ERR,ERROR,*999)
                            ENDIF
                          ENDIF
                        ELSE
                          SELECT CASE(DYNAMIC_SOLVER%ORDER)
                          CASE(SOLVER_DYNAMIC_FIRST_ORDER)
                            SELECT CASE(DYNAMIC_SOLVER%DEGREE)
                            CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
                              !Do nothing
                            CASE(SOLVER_DYNAMIC_SECOND_DEGREE)                                  
                              CALL FIELD_PARAMETER_SET_UPDATE_FINISH(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                & FIELD_INITIAL_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                            CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
                              CALL FIELD_PARAMETER_SET_UPDATE_FINISH(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                & FIELD_INITIAL_VELOCITY_SET_TYPE,ERR,ERROR,*999)
                              CALL FIELD_PARAMETER_SET_UPDATE_FINISH(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                & FIELD_INITIAL_ACCELERATION_SET_TYPE,ERR,ERROR,*999)
                            CASE DEFAULT
                              LOCAL_ERROR="The dynamic solver degree of "// &
                                & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))//" is invalid."
                              CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                            END SELECT
                          CASE(SOLVER_DYNAMIC_SECOND_ORDER)
                            IF(DYNAMIC_SOLVER%DEGREE==SOLVER_DYNAMIC_THIRD_DEGREE) THEN
                              CALL FIELD_PARAMETER_SET_UPDATE_FINISH(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                & FIELD_INITIAL_ACCELERATION_SET_TYPE,ERR,ERROR,*999)
                            ENDIF
                          CASE DEFAULT
                            LOCAL_ERROR="The dynamic solver order of "// &
                              & TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%ORDER,"*",ERR,ERROR))//" is invalid."
                            CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
                          END SELECT
                        ENDIF
                      ENDDO !equations_set_idx
                    ELSE
                      CALL FLAG_ERROR("Solver vector is not associated.",ERR,ERROR,*998)
                    ENDIF
                  ELSE
                    CALL FLAG_ERROR("Solver matrix is not associated.",ERR,ERROR,*998)
                  ENDIF
                ENDDO !solver_matrix_idx
              ELSE
                CALL FLAG_ERROR("Solver matrices solution mapping is not associated.",ERR,ERROR,*998)
              ENDIF
            ELSE
              CALL FLAG_ERROR("Solver equations solver matrices are not associated.",ERR,ERROR,*998)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver dynamic solver is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver has not been finished.",ERR,ERROR,*998)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
    
    CALL EXITS("SOLVER_VARIABLES_DYNAMIC_FIELD_UPDATE")
    RETURN
999 IF(ASSOCIATED(SOLVER_DATA)) CALL DISTRIBUTED_VECTOR_DATA_RESTORE(SOLVER_VECTOR,SOLVER_DATA,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_VARIABLES_DYNAMIC_FIELD_UPDATE",ERR,ERROR)    
    CALL EXITS("SOLVER_VARIABLES_DYNAMIC_FIELD_UPDATE")
    RETURN 1
   
  END SUBROUTINE SOLVER_VARIABLES_DYNAMIC_FIELD_UPDATE

  !
  !================================================================================================================================
  !

  !>Update the field values form the dynamic factor * current solver values AND add in mean predicted displacements
  SUBROUTINE SOLVER_VARIABLES_DYNAMIC_NONLINEAR_UPDATE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to update the variables from
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string

    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR,DYNAMIC_VARIABLE_TYPE,equations_set_idx,solver_dof_idx,solver_matrix_idx,variable_dof
    REAL(DP) :: additive_constant,DELTA_T,VALUE,variable_coefficient
    REAL(DP) :: DYNAMIC_ALPHA_FACTOR, DYNAMIC_U_FACTOR
    INTEGER(INTG) :: variable_idx,VARIABLE_TYPE
    REAL(DP), POINTER :: SOLVER_DATA(:), MEAN_DATA(:) 
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: SOLVER_VECTOR,PREDICTED_DISPLACEMENT_VECTOR
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: DEPENDENT_VARIABLE
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(EQUATIONS_MAPPING_DYNAMIC_TYPE), POINTER :: DYNAMIC_MAPPING
    TYPE(EQUATIONS_MAPPING_TYPE), POINTER :: EQUATIONS_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(SOLVER_MATRIX_TYPE), POINTER :: SOLVER_MATRIX
    TYPE(VARYING_STRING) :: DUMMY_ERROR,LOCAL_ERROR


    TYPE(DYNAMIC_SOLVER_TYPE), POINTER :: DYNAMIC_SOLVER
    TYPE(EQUATIONS_TYPE), POINTER :: EQUATIONS

    !STABILITY_TEST under investigation
    LOGICAL :: STABILITY_TEST
    !.FALSE. guarantees weighting as described in OpenCMISS notes
    !.TRUE. weights mean predicted field rather than the whole NL contribution
    !-> to be removed later
    STABILITY_TEST=.FALSE.

    NULLIFY(SOLVER_DATA)
    
    CALL ENTERS("SOLVER_VARIABLES_DYNAMIC_NONLINEAR_UPDATE",ERR,ERROR,*998)
    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
        IF(ASSOCIATED(SOLVER%LINKING_SOLVER)) THEN
        DYNAMIC_SOLVER=>SOLVER%LINKING_SOLVER%DYNAMIC_SOLVER
          !Define the dynamic alpha factor
          IF(ASSOCIATED(DYNAMIC_SOLVER)) THEN
            IF(DYNAMIC_SOLVER%SOLVER_INITIALISED) THEN
              DELTA_T=DYNAMIC_SOLVER%TIME_INCREMENT
              SELECT CASE(DYNAMIC_SOLVER%DEGREE)
                CASE(SOLVER_DYNAMIC_FIRST_DEGREE)
                  DYNAMIC_ALPHA_FACTOR=DELTA_T
                  DYNAMIC_U_FACTOR=1.0_DP
                CASE(SOLVER_DYNAMIC_SECOND_DEGREE)
                  DYNAMIC_ALPHA_FACTOR=DELTA_T*DELTA_T/2.0_DP
                  DYNAMIC_U_FACTOR=1.0_DP
                CASE(SOLVER_DYNAMIC_THIRD_DEGREE)
                  DYNAMIC_ALPHA_FACTOR=DELTA_T*DELTA_T*DELTA_T/6.0_DP
                  DYNAMIC_U_FACTOR=1.0_DP
                CASE DEFAULT
                  LOCAL_ERROR="The dynamic solver degree of "//TRIM(NUMBER_TO_VSTRING(DYNAMIC_SOLVER%DEGREE,"*",ERR,ERROR))// &
                    & " is invalid."
                  CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
              END SELECT
            ENDIF
          ENDIF
        ELSE
          CALL FLAG_ERROR("Dynamic solver linking solver is not associated.",ERR,ERROR,*999)
        ENDIF
        !Set the dependent field for calculating the nonlinear residual and Jacobian values
        IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
         SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
          IF(ASSOCIATED(SOLVER_MATRICES)) THEN
            SOLVER_MAPPING=>SOLVER_MATRICES%SOLVER_MAPPING
            IF(ASSOCIATED(SOLVER_MAPPING)) THEN            
              DO solver_matrix_idx=1,SOLVER_MATRICES%NUMBER_OF_MATRICES
                SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(solver_matrix_idx)%PTR
                IF(ASSOCIATED(SOLVER_MATRIX)) THEN
                  SOLVER_VECTOR=>SOLVER_MATRIX%SOLVER_VECTOR
                  IF(ASSOCIATED(SOLVER_VECTOR)) THEN
                    !Get the solver variables data                  
                    CALL DISTRIBUTED_VECTOR_DATA_GET(SOLVER_VECTOR,SOLVER_DATA,ERR,ERROR,*999)   
                    !Loop over the solver variable dofs
                    DO solver_dof_idx=1,SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)%NUMBER_OF_DOFS
                      !Loop over the equations sets associated with this dof
                      DO equations_set_idx=1,SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                        & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%NUMBER_OF_EQUATIONS_SETS  
                        DEPENDENT_VARIABLE=>SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                          & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%VARIABLE(equations_set_idx)%PTR
                        EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                        IF(ASSOCIATED(EQUATIONS_SET)) THEN
                          DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                          EQUATIONS=>EQUATIONS_SET%EQUATIONS
                          IF(ASSOCIATED(DEPENDENT_VARIABLE)) THEN
                            VARIABLE_TYPE=DEPENDENT_VARIABLE%VARIABLE_TYPE
                            IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                              IF(ASSOCIATED(EQUATIONS)) THEN
                                EQUATIONS_MAPPING=>EQUATIONS%EQUATIONS_MAPPING
                                IF(ASSOCIATED(EQUATIONS_MAPPING)) THEN
                                  DYNAMIC_MAPPING=>EQUATIONS_MAPPING%DYNAMIC_MAPPING
                                  IF(ASSOCIATED(DYNAMIC_MAPPING)) THEN
                                    DYNAMIC_VARIABLE_TYPE=DYNAMIC_MAPPING%DYNAMIC_VARIABLE_TYPE
                                    !Get the predicted displacement data       
                                    NULLIFY(PREDICTED_DISPLACEMENT_VECTOR)
                                    CALL FIELD_PARAMETER_SET_VECTOR_GET(DEPENDENT_FIELD,DYNAMIC_VARIABLE_TYPE, &
                                      & FIELD_PREDICTED_DISPLACEMENT_SET_TYPE,PREDICTED_DISPLACEMENT_VECTOR, &
                                      & ERR,ERROR,*999)
                                    NULLIFY(MEAN_DATA)
                                    CALL DISTRIBUTED_VECTOR_DATA_GET(PREDICTED_DISPLACEMENT_VECTOR,MEAN_DATA,ERR,ERROR,*999)   
                                   !Get the dependent field variable dof the solver dof is mapped to
                                   variable_dof=SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                                     & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%VARIABLE_DOF(equations_set_idx)
                                   variable_coefficient=SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                                     & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%VARIABLE_COEFFICIENT(equations_set_idx)
                                   additive_constant=SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                                     & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%ADDITIVE_CONSTANT(equations_set_idx)

                                   VALUE=0.0_DP 
                                   !Calculate solver data only
                                   VALUE=SOLVER_DATA(solver_dof_idx)*variable_coefficient+additive_constant
                                   !Set solver data to FIELD_INCREMENTAL_VALUES_SET_TYPE in order to store solver data before modification
                                   CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD,VARIABLE_TYPE, &
                                     & FIELD_INCREMENTAL_VALUES_SET_TYPE,variable_dof,VALUE,ERR,ERROR,*999)
                                   !Calculate modified input values for residual and Jacobian calculation
                                   IF(STABILITY_TEST) THEN
                                     VALUE=VALUE*DYNAMIC_SOLVER%THETA(1)
                                   ENDIF
                                   VALUE=(VALUE*DYNAMIC_ALPHA_FACTOR)+MEAN_DATA(variable_dof)
                                   CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD,VARIABLE_TYPE, &
                                     & FIELD_VALUES_SET_TYPE,variable_dof,VALUE,ERR,ERROR,*999)
                                  ELSE
                                    CALL FLAG_ERROR("Dynamic mapping is not associated.",ERR,ERROR,*999)
                                  ENDIF
                                ELSE
                                  CALL FLAG_ERROR("Equations mapping is not associated.",ERR,ERROR,*999)
                                ENDIF
                              ELSE
                                CALL FLAG_ERROR("Equations are not associated.",ERR,ERROR,*999)
                              ENDIF
                            ELSE
                              CALL FLAG_ERROR("Dependent field is not associated.",ERR,ERROR,*999)
                            ENDIF
                          ELSE
                            CALL FLAG_ERROR("Dependent variable is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ENDDO !equations_set_idx
                    ENDDO !solver_dof_idx

                    !Restore the solver dof data
                    CALL DISTRIBUTED_VECTOR_DATA_RESTORE(SOLVER_VECTOR,SOLVER_DATA,ERR,ERROR,*999)
                    !Start the transfer of the field dofs
                    DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                      EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                      IF(ASSOCIATED(EQUATIONS_SET)) THEN
                        DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                        DO variable_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                          & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%NUMBER_OF_VARIABLES
                          VARIABLE_TYPE=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                            & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%VARIABLE_TYPES(variable_idx)
                          CALL FIELD_PARAMETER_SET_UPDATE_START(DEPENDENT_FIELD,VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
                        ENDDO !variable_idx
                      ELSE
                        CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ENDDO !equations_set_idx
                    !Finish the transfer of the field dofs
                    DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                      EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                      DO variable_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                        & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%NUMBER_OF_VARIABLES
                        VARIABLE_TYPE=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                          & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%VARIABLE_TYPES(variable_idx)
                        CALL FIELD_PARAMETER_SET_UPDATE_FINISH(DEPENDENT_FIELD,VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
                      ENDDO !variable_idx
                    ENDDO !equations_set_idx
                  ELSE
                    CALL FLAG_ERROR("Solver vector is not associated.",ERR,ERROR,*998)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("Solver matrix is not associated.",ERR,ERROR,*998)
                ENDIF
              ENDDO !solver_matrix_idx
            ELSE
              CALL FLAG_ERROR("Solver matrices solution mapping is not associated.",ERR,ERROR,*998)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Solver equations solver matrices are not associated.",ERR,ERROR,*998)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver has not been finished.",ERR,ERROR,*998)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
    
    CALL EXITS("SOLVER_VARIABLES_DYNAMIC_NONLINEAR_UPDATE")
    RETURN
999 IF(ASSOCIATED(SOLVER_DATA)) CALL DISTRIBUTED_VECTOR_DATA_RESTORE(SOLVER_VECTOR,SOLVER_DATA,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_VARIABLES_DYNAMIC_NONLINEAR_UPDATE",ERR,ERROR)    
    CALL EXITS("SOLVER_VARIABLES_DYNAMIC_NONLINEAR_UPDATE")
    RETURN 1
  END SUBROUTINE SOLVER_VARIABLES_DYNAMIC_NONLINEAR_UPDATE 


  !
  !================================================================================================================================
  !

  !>Updates the dependent variables from the solver solution for static solvers
  SUBROUTINE SOLVER_VARIABLES_FIELD_UPDATE(SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<A pointer the solver to update the variables from
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR,equations_set_idx,solver_dof_idx,solver_matrix_idx,variable_dof,variable_idx,VARIABLE_TYPE
    REAL(DP) :: additive_constant,VALUE,variable_coefficient
    REAL(DP), POINTER :: SOLVER_DATA(:)
    TYPE(DISTRIBUTED_VECTOR_TYPE), POINTER :: SOLVER_VECTOR
    TYPE(EQUATIONS_SET_TYPE), POINTER :: EQUATIONS_SET
    TYPE(FIELD_TYPE), POINTER :: DEPENDENT_FIELD
    TYPE(FIELD_VARIABLE_TYPE), POINTER :: DEPENDENT_VARIABLE
    TYPE(SOLVER_EQUATIONS_TYPE), POINTER :: SOLVER_EQUATIONS
    TYPE(SOLVER_MAPPING_TYPE), POINTER :: SOLVER_MAPPING
    TYPE(SOLVER_MATRICES_TYPE), POINTER :: SOLVER_MATRICES
    TYPE(SOLVER_MATRIX_TYPE), POINTER :: SOLVER_MATRIX
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    NULLIFY(SOLVER_DATA)
    
    CALL ENTERS("SOLVER_VARIABLES_FIELD_UPDATE",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVER)) THEN
      IF(SOLVER%SOLVER_FINISHED) THEN
        SOLVER_EQUATIONS=>SOLVER%SOLVER_EQUATIONS
        IF(ASSOCIATED(SOLVER_EQUATIONS)) THEN
          SOLVER_MATRICES=>SOLVER_EQUATIONS%SOLVER_MATRICES
          IF(ASSOCIATED(SOLVER_MATRICES)) THEN
            SOLVER_MAPPING=>SOLVER_MATRICES%SOLVER_MAPPING
            IF(ASSOCIATED(SOLVER_MAPPING)) THEN            
              DO solver_matrix_idx=1,SOLVER_MATRICES%NUMBER_OF_MATRICES
                SOLVER_MATRIX=>SOLVER_MATRICES%MATRICES(solver_matrix_idx)%PTR
                IF(ASSOCIATED(SOLVER_MATRIX)) THEN
                  SOLVER_VECTOR=>SOLVER_MATRIX%SOLVER_VECTOR
                  IF(ASSOCIATED(SOLVER_VECTOR)) THEN
                    !Get the solver variables data                  
                    CALL DISTRIBUTED_VECTOR_DATA_GET(SOLVER_VECTOR,SOLVER_DATA,ERR,ERROR,*999)             
                    !Loop over the solver variable dofs
                    DO solver_dof_idx=1,SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)%NUMBER_OF_DOFS
                      !Loop over the equations sets associated with this dof
                      DO equations_set_idx=1,SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                        & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%NUMBER_OF_EQUATIONS_SETS                        
                        DEPENDENT_VARIABLE=>SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                          & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%VARIABLE(equations_set_idx)%PTR
                        IF(ASSOCIATED(DEPENDENT_VARIABLE)) THEN
                          VARIABLE_TYPE=DEPENDENT_VARIABLE%VARIABLE_TYPE
                          DEPENDENT_FIELD=>DEPENDENT_VARIABLE%FIELD
                          IF(ASSOCIATED(DEPENDENT_FIELD)) THEN
                            !Get the dependent field variable dof the solver dof is mapped to
                            variable_dof=SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                              & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%VARIABLE_DOF(equations_set_idx)
                            variable_coefficient=SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                              & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%VARIABLE_COEFFICIENT(equations_set_idx)
                            additive_constant=SOLVER_MAPPING%SOLVER_COL_TO_EQUATIONS_SETS_MAP(solver_matrix_idx)% &
                              & SOLVER_DOF_TO_VARIABLE_MAPS(solver_dof_idx)%ADDITIVE_CONSTANT(equations_set_idx)
                            !Set the dependent field variable dof
                            VALUE=SOLVER_DATA(solver_dof_idx)*variable_coefficient+additive_constant
                            CALL FIELD_PARAMETER_SET_UPDATE_LOCAL_DOF(DEPENDENT_FIELD,VARIABLE_TYPE,FIELD_VALUES_SET_TYPE, &
                              & variable_dof,VALUE,ERR,ERROR,*999)
                          ELSE
                            CALL FLAG_ERROR("Dependent field is not associated.",ERR,ERROR,*999)
                          ENDIF
                        ELSE
                          CALL FLAG_ERROR("Dependent variable is not associated.",ERR,ERROR,*999)
                        ENDIF
                      ENDDO !equations_set_idx
                    ENDDO !solver_dof_idx
                    !Restore the solver dof data
                    CALL DISTRIBUTED_VECTOR_DATA_RESTORE(SOLVER_VECTOR,SOLVER_DATA,ERR,ERROR,*999)
                    !Start the transfer of the field dofs
                    DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                      EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                      IF(ASSOCIATED(EQUATIONS_SET)) THEN
                        DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                        DO variable_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                          & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%NUMBER_OF_VARIABLES
                          VARIABLE_TYPE=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                            & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%VARIABLE_TYPES(variable_idx)
                          CALL FIELD_PARAMETER_SET_UPDATE_START(DEPENDENT_FIELD,VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
                        ENDDO !variable_idx
                      ELSE
                        CALL FLAG_ERROR("Equations set is not associated.",ERR,ERROR,*999)
                      ENDIF
                    ENDDO !equations_set_idx
                    !Finish the transfer of the field dofs
                    DO equations_set_idx=1,SOLVER_MAPPING%NUMBER_OF_EQUATIONS_SETS
                      EQUATIONS_SET=>SOLVER_MAPPING%EQUATIONS_SETS(equations_set_idx)%PTR
                      DEPENDENT_FIELD=>EQUATIONS_SET%DEPENDENT%DEPENDENT_FIELD
                      DO variable_idx=1,SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                        & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%NUMBER_OF_VARIABLES
                        VARIABLE_TYPE=SOLVER_MAPPING%EQUATIONS_SET_TO_SOLVER_MAP(equations_set_idx)% &
                          & EQUATIONS_TO_SOLVER_MATRIX_MAPS_SM(solver_matrix_idx)%VARIABLE_TYPES(variable_idx)
                        CALL FIELD_PARAMETER_SET_UPDATE_FINISH(DEPENDENT_FIELD,VARIABLE_TYPE,FIELD_VALUES_SET_TYPE,ERR,ERROR,*999)
                      ENDDO !variable_idx
                    ENDDO !equations_set_idx
                  ELSE
                    CALL FLAG_ERROR("Solver vector is not associated.",ERR,ERROR,*998)
                  ENDIF
                ELSE
                  CALL FLAG_ERROR("Solver matrix is not associated.",ERR,ERROR,*998)
                ENDIF
              ENDDO !solver_matrix_idx
            ELSE
              CALL FLAG_ERROR("Solver matrices solution mapping is not associated.",ERR,ERROR,*998)
            ENDIF
          ELSE
            CALL FLAG_ERROR("Solver equations solver matrices are not associated.",ERR,ERROR,*998)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solver solver equations is not associated.",ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Solver has not been finished.",ERR,ERROR,*998)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*998)
    ENDIF
    
    CALL EXITS("SOLVER_VARIABLES_FIELD_UPDATE")
    RETURN
999 IF(ASSOCIATED(SOLVER_DATA)) CALL DISTRIBUTED_VECTOR_DATA_RESTORE(SOLVER_VECTOR,SOLVER_DATA,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVER_VARIABLES_FIELD_UPDATE",ERR,ERROR)    
    CALL EXITS("SOLVER_VARIABLES_FIELD_UPDATE")
    RETURN 1
    
  END SUBROUTINE SOLVER_VARIABLES_FIELD_UPDATE
  
  !
  !================================================================================================================================
  !

  !>Finish the creation of solvers.
  SUBROUTINE SOLVERS_CREATE_FINISH(SOLVERS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVERS_TYPE), POINTER :: SOLVERS !<A pointer to the solvers to finish the creation of
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: solver_idx
    TYPE(CONTROL_LOOP_TYPE), POINTER :: CONTROL_LOOP
    TYPE(SOLVER_TYPE), POINTER :: SOLVER
   
    CALL ENTERS("SOLVERS_CREATE_FINISH",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVERS)) THEN
      IF(SOLVERS%SOLVERS_FINISHED) THEN
        CALL FLAG_ERROR("Solvers has already been finished.",ERR,ERROR,*999)
      ELSE        
        CONTROL_LOOP=>SOLVERS%CONTROL_LOOP
        IF(ASSOCIATED(CONTROL_LOOP)) THEN          
          !Finish the solver creation
          IF(ALLOCATED(SOLVERS%SOLVERS)) THEN
            DO solver_idx=1,SOLVERS%NUMBER_OF_SOLVERS
              SOLVER=>SOLVERS%SOLVERS(solver_idx)%PTR
              IF(ASSOCIATED(SOLVER)) THEN
                CALL SOLVER_CREATE_FINISH(SOLVER,ERR,ERROR,*999)
              ELSE
                CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
              ENDIF
            ENDDO !solver_idx            
            SOLVERS%SOLVERS_FINISHED=.TRUE.
          ELSE
            CALL FLAG_ERROR("Solvers solvers is not allocated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          CALL FLAG_ERROR("Solvers control loop is not associated.",ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solvers is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVERS_CREATE_FINISH")
    RETURN
999 CALL ERRORS("SOLVERS_CREATE_FINISH",ERR,ERROR)
    CALL EXITS("SOLVERS_CREATE_FINISH")
    RETURN 1
    
  END SUBROUTINE SOLVERS_CREATE_FINISH

  !
  !================================================================================================================================
  !

  !>Start the creation of a solvers for the control loop. 
  SUBROUTINE SOLVERS_CREATE_START(CONTROL_LOOP,SOLVERS,ERR,ERROR,*)

    !Argument variables
    TYPE(CONTROL_LOOP_TYPE), POINTER :: CONTROL_LOOP !<A pointer to the control loop to create the solvers for
    TYPE(SOLVERS_TYPE), POINTER :: SOLVERS !<On exit, a pointer to the solvers. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR

    CALL ENTERS("SOLVERS_CREATE_START",ERR,ERROR,*999)
    
    IF(ASSOCIATED(CONTROL_LOOP)) THEN
      IF(CONTROL_LOOP%CONTROL_LOOP_FINISHED) THEN
        IF(CONTROL_LOOP%NUMBER_OF_SUB_LOOPS==0) THEN
          IF(ASSOCIATED(SOLVERS)) THEN
            CALL FLAG_ERROR("Solvers is already associated.",ERR,ERROR,*999)
          ELSE
            NULLIFY(SOLVERS)
            !Initialise the solvers
            CALL SOLVERS_INITIALISE(CONTROL_LOOP,ERR,ERROR,*999)
            !Return the pointer
            SOLVERS=>CONTROL_LOOP%SOLVERS
          ENDIF
        ELSE
          LOCAL_ERROR="Invalid control loop setup. The specified control loop has "// &
            & TRIM(NUMBER_TO_VSTRING(CONTROL_LOOP%NUMBER_OF_SUB_LOOPS,"*",ERR,ERROR))// &
            & " sub loops. To create solvers the control loop must have 0 sub loops."          
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ELSE
        CALL FLAG_ERROR("Control loop has not been finished.",ERR,ERROR,*999)
      ENDIF
    ELSE
      CALL FLAG_ERROR("Control loop is not associated.",ERR,ERROR,*999)
    ENDIF
    
    CALL EXITS("SOLVERS_CREATE_START")
    RETURN
999 CALL ERRORS("SOLVERS_CREATE_START",ERR,ERROR)
    CALL EXITS("SOLVERS_CREATE_START")
    RETURN 1
  END SUBROUTINE SOLVERS_CREATE_START
  
  !
  !================================================================================================================================
  !

  !>Destroys the solvers
  SUBROUTINE SOLVERS_DESTROY(SOLVERS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVERS_TYPE), POINTER :: SOLVERS !<A pointer to the solvers to destroy
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables

    CALL ENTERS("SOLVERS_DESTROY",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVERS)) THEN
      CALL SOLVERS_FINALISE(SOLVERS,ERR,ERROR,*999)
    ELSE
      CALL FLAG_ERROR("Solvers is not associated.",ERR,ERROR,*999)
    ENDIF
       
    CALL EXITS("SOLVERS_DESTROY")
    RETURN
999 CALL ERRORS("SOLVERS_DESTROY",ERR,ERROR)
    CALL EXITS("SOLVERS_DESTROY")
    RETURN 1
    
  END SUBROUTINE SOLVERS_DESTROY

  !
  !================================================================================================================================
  !

  !>Finalises the solvers and deallocates all memory
  SUBROUTINE SOLVERS_FINALISE(SOLVERS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVERS_TYPE), POINTER :: SOLVERS !<A pointer to the solvers to finalise
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: solver_idx
 
    CALL ENTERS("SOLVERS_FINALISE",ERR,ERROR,*999)

    IF(ASSOCIATED(SOLVERS)) THEN
      IF(ALLOCATED(SOLVERS%SOLVERS)) THEN
        DO solver_idx=1,SIZE(SOLVERS%SOLVERS,1)
          CALL SOLVER_FINALISE(SOLVERS%SOLVERS(solver_idx)%PTR,ERR,ERROR,*999)
        ENDDO !solver_idx
        DEALLOCATE(SOLVERS%SOLVERS)
      ENDIF
      DEALLOCATE(SOLVERS)
    ENDIF
       
    CALL EXITS("SOLVERS_FINALISE")
    RETURN
999 CALL ERRORS("SOLVERS_FINALISE",ERR,ERROR)
    CALL EXITS("SOLVERS_FINALISE")
    RETURN 1
  END SUBROUTINE SOLVERS_FINALISE
  
  !
  !================================================================================================================================
  !

  !>Initialises the solvers for a control loop.
  SUBROUTINE SOLVERS_INITIALISE(CONTROL_LOOP,ERR,ERROR,*)

    !Argument variables
    TYPE(CONTROL_LOOP_TYPE), POINTER :: CONTROL_LOOP !<A pointer to the control loop to initialise the solvers for
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: DUMMY_ERR,solver_idx
    TYPE(VARYING_STRING) :: DUMMY_ERROR

    CALL ENTERS("SOLVERS_INITIALISE",ERR,ERROR,*998)

    IF(ASSOCIATED(CONTROL_LOOP)) THEN
      IF(ASSOCIATED(CONTROL_LOOP%SOLVERS)) THEN
        CALL FLAG_ERROR("Solvers is already allocated for this control loop.",ERR,ERROR,*998)
      ELSE
        ALLOCATE(CONTROL_LOOP%SOLVERS,STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate control loop solvers.",ERR,ERROR,*999)
        CONTROL_LOOP%SOLVERS%CONTROL_LOOP=>CONTROL_LOOP
        CONTROL_LOOP%SOLVERS%SOLVERS_FINISHED=.FALSE.
        CONTROL_LOOP%SOLVERS%NUMBER_OF_SOLVERS=1
        ALLOCATE(CONTROL_LOOP%SOLVERS%SOLVERS(CONTROL_LOOP%SOLVERS%NUMBER_OF_SOLVERS),STAT=ERR)
        IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solvers solvers.",ERR,ERROR,*999)
        DO solver_idx=1,CONTROL_LOOP%SOLVERS%NUMBER_OF_SOLVERS
          NULLIFY(CONTROL_LOOP%SOLVERS%SOLVERS(solver_idx)%PTR)
          CALL SOLVER_INITIALISE(CONTROL_LOOP%SOLVERS,solver_idx,ERR,ERROR,*999)
        ENDDO !solver_idx
      ENDIF
    ELSE
      CALL FLAG_ERROR("Control loop is not associated.",ERR,ERROR,*998)
    ENDIF
       
    CALL EXITS("SOLVERS_INITIALISE")
    RETURN
999 CALL SOLVERS_FINALISE(CONTROL_LOOP%SOLVERS,DUMMY_ERR,DUMMY_ERROR,*998)
998 CALL ERRORS("SOLVERS_INITIALISE",ERR,ERROR)
    CALL EXITS("SOLVERS_INITIALISE")
    RETURN 1
    
  END SUBROUTINE SOLVERS_INITIALISE
  
 
  !
  !================================================================================================================================
  !

  !>Sets/changes the number of solvers.
  SUBROUTINE SOLVERS_NUMBER_SET(SOLVERS,NUMBER_OF_SOLVERS,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVERS_TYPE), POINTER :: SOLVERS !<A pointer to the solvers to set the number for
    INTEGER(INTG), INTENT(IN) :: NUMBER_OF_SOLVERS !<The number of solvers to set
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    INTEGER(INTG) :: solver_idx, OLD_NUMBER_OF_SOLVERS
    TYPE(SOLVER_PTR_TYPE), ALLOCATABLE :: OLD_SOLVERS(:)
    TYPE(VARYING_STRING) :: LOCAL_ERROR
 
    CALL ENTERS("SOLVERS_NUMBER_SET",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVERS)) THEN
      IF(SOLVERS%SOLVERS_FINISHED) THEN
        CALL FLAG_ERROR("Solvers have already been finished.",ERR,ERROR,*998)
      ELSE
        IF(NUMBER_OF_SOLVERS>0) THEN
          OLD_NUMBER_OF_SOLVERS=SOLVERS%NUMBER_OF_SOLVERS
          IF(NUMBER_OF_SOLVERS/=OLD_NUMBER_OF_SOLVERS) THEN
            ALLOCATE(OLD_SOLVERS(OLD_NUMBER_OF_SOLVERS),STAT=ERR)
            IF(ERR/=0) CALL FLAG_ERROR("Could not allocate old solvers.",ERR,ERROR,*999)
            DO solver_idx=1,OLD_NUMBER_OF_SOLVERS
              OLD_SOLVERS(solver_idx)%PTR=>SOLVERS%SOLVERS(solver_idx)%PTR
            ENDDO !solver_idx
            IF(ALLOCATED(SOLVERS%SOLVERS)) DEALLOCATE(SOLVERS%SOLVERS)
            ALLOCATE(SOLVERS%SOLVERS(NUMBER_OF_SOLVERS),STAT=ERR)
            IF(ERR/=0) CALL FLAG_ERROR("Could not allocate solvers.",ERR,ERROR,*999)
            IF(NUMBER_OF_SOLVERS>OLD_NUMBER_OF_SOLVERS) THEN
              DO solver_idx=1,OLD_NUMBER_OF_SOLVERS
                SOLVERS%SOLVERS(solver_idx)%PTR=>OLD_SOLVERS(solver_idx)%PTR
              ENDDO !solver_idx
              SOLVERS%NUMBER_OF_SOLVERS=NUMBER_OF_SOLVERS
              DO solver_idx=OLD_NUMBER_OF_SOLVERS+1,NUMBER_OF_SOLVERS
                NULLIFY(SOLVERS%SOLVERS(solver_idx)%PTR)
                CALL SOLVER_INITIALISE(SOLVERS,solver_idx,ERR,ERROR,*999)
              ENDDO !solution_idx
            ELSE
              DO solver_idx=1,NUMBER_OF_SOLVERS
                SOLVERS%SOLVERS(solver_idx)%PTR=>OLD_SOLVERS(solver_idx)%PTR
              ENDDO !solver_idx
              DO solver_idx=NUMBER_OF_SOLVERS+1,OLD_NUMBER_OF_SOLVERS
                CALL SOLVER_FINALISE(OLD_SOLVERS(solver_idx)%PTR,ERR,ERROR,*999)
              ENDDO !solver_idx
              SOLVERS%NUMBER_OF_SOLVERS=NUMBER_OF_SOLVERS
            ENDIF
          ENDIF
        ELSE
          LOCAL_ERROR="The specified number of solvers of "//TRIM(NUMBER_TO_VSTRING(NUMBER_OF_SOLVERS,"*",ERR,ERROR))// &
            & " is invalid. The number of solvers must be > 0."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*998)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solvers is not associated.",ERR,ERROR,*998)
    ENDIF
       
    CALL EXITS("SOLVERS_NUMBER_SET")
    RETURN
999 IF(ALLOCATED(OLD_SOLVERS)) DEALLOCATE(OLD_SOLVERS)
998 CALL ERRORS("SOLVERS_NUMBER_SET",ERR,ERROR)
    CALL EXITS("SOLVERS_NUMBER_SET")
    RETURN 1
    
  END SUBROUTINE SOLVERS_NUMBER_SET
  
  !
  !================================================================================================================================
  !

  !>Returns a pointer to the specified solver in the list of solvers.
  SUBROUTINE SOLVERS_SOLVER_GET(SOLVERS,SOLVER_INDEX,SOLVER,ERR,ERROR,*)

    !Argument variables
    TYPE(SOLVERS_TYPE), POINTER :: SOLVERS !<A pointer to the solvers to get the solver for
    INTEGER(INTG), INTENT(IN) :: SOLVER_INDEX !<The specified solver to get
    TYPE(SOLVER_TYPE), POINTER :: SOLVER !<On exit, a pointer to the specified solver. Must not be associated on entry.
    INTEGER(INTG), INTENT(OUT) :: ERR !<The error code
    TYPE(VARYING_STRING), INTENT(OUT) :: ERROR !<The error string
    !Local Variables
    TYPE(VARYING_STRING) :: LOCAL_ERROR
 
    CALL ENTERS("SOLVERS_SOLVER_GET",ERR,ERROR,*998)

    IF(ASSOCIATED(SOLVERS)) THEN
      IF(ASSOCIATED(SOLVER)) THEN
        CALL FLAG_ERROR("Solver is already associated.",ERR,ERROR,*998)
      ELSE
        NULLIFY(SOLVER)
        IF(SOLVER_INDEX>0.AND.SOLVER_INDEX<=SOLVERS%NUMBER_OF_SOLVERS) THEN
          IF(ALLOCATED(SOLVERS%SOLVERS)) THEN
            SOLVER=>SOLVERS%SOLVERS(SOLVER_INDEX)%PTR
            IF(.NOT.ASSOCIATED(SOLVER)) CALL FLAG_ERROR("Solver is not associated.",ERR,ERROR,*999)
          ELSE
            CALL FLAG_ERROR("Solvers solvers is not associated.",ERR,ERROR,*999)
          ENDIF
        ELSE
          LOCAL_ERROR="The specified solver index of "//TRIM(NUMBER_TO_VSTRING(SOLVER_INDEX,"*",ERR,ERROR))// &
            & " is invalid. The solver index must be >= 1 and <= "// &
            & TRIM(NUMBER_TO_VSTRING(SOLVERS%NUMBER_OF_SOLVERS,"*",ERR,ERROR))//"."
          CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
        ENDIF
      ENDIF
    ELSE
      CALL FLAG_ERROR("Solvers is not associated.",ERR,ERROR,*998)
    ENDIF
       
    CALL EXITS("SOLVERS_SOLVER_GET")
    RETURN
999 NULLIFY(SOLVER)
998 CALL ERRORS("SOLVERS_SOLVER_GET",ERR,ERROR)
    CALL EXITS("SOLVERS_SOLVER_GET")
    RETURN 1
    
  END SUBROUTINE SOLVERS_SOLVER_GET
     
  !
  !================================================================================================================================
  !

        
END MODULE SOLVER_ROUTINES

!
!================================================================================================================================
!

!>Called from the PETSc TS solvers to monitor the dynamic solver
SUBROUTINE SOLVER_TIME_STEPPING_MONITOR_PETSC(TS,STEPS,TIME,X,CTX,ERR)

  USE BASE_ROUTINES
  USE CMISS_PETSC_TYPES
  USE ISO_VARYING_STRING
  USE KINDS
  USE SOLVER_ROUTINES
  USE STRINGS
  USE TYPES

  IMPLICIT NONE
  
  !Argument variables
  TYPE(PETSC_TS_TYPE), INTENT(INOUT) :: TS !<The PETSc TS type
  INTEGER(INTG), INTENT(INOUT) :: STEPS !<The iteration number
  REAL(DP), INTENT(INOUT) :: TIME !<The current time
  TYPE(PETSC_VEC_TYPE), INTENT(INOUT) :: X !<The current iterate
  TYPE(SOLVER_TYPE), POINTER :: CTX !<The passed through context
  INTEGER(INTG), INTENT(INOUT) :: ERR !<The error code
  !Local Variables
  TYPE(DAE_SOLVER_TYPE), POINTER :: DAE_SOLVER
  TYPE(VARYING_STRING) :: ERROR,LOCAL_ERROR

  IF(ASSOCIATED(CTX)) THEN
    IF(CTX%SOLVE_TYPE==SOLVER_DAE_TYPE) THEN
      DAE_SOLVER=>CTX%DAE_SOLVER

      CALL SOLVER_TIME_STEPPING_MONITOR(DAE_SOLVER,STEPS,TIME,ERR,ERROR,*999)

    ELSE
      LOCAL_ERROR="Invalid solve type. The solve type of "//TRIM(NUMBER_TO_VSTRING(CTX%SOLVE_TYPE,"*",ERR,ERROR))// &
        & " does not correspond to a differntial-algebraic equations solver."
      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    ENDIF      
  ELSE
    CALL FLAG_ERROR("Solver context is not associated.",ERR,ERROR,*999)
  ENDIF
  
  RETURN
999 CALL WRITE_ERROR(ERR,ERROR,*998)
998 CALL FLAG_WARNING("Error monitoring differential-algebraic equations solve.",ERR,ERROR,*997)
997 RETURN    
END SUBROUTINE SOLVER_TIME_STEPPING_MONITOR_PETSC

!
!================================================================================================================================
!

!>Called from the PETSc SNES solvers to monitor the Newton nonlinear solver
SUBROUTINE SOLVER_NONLINEAR_MONITOR_PETSC(SNES,ITS,NORM,CTX,ERR)

  USE BASE_ROUTINES
  USE CMISS_PETSC_TYPES
  USE ISO_VARYING_STRING
  USE KINDS
  USE SOLVER_ROUTINES
  USE STRINGS
  USE TYPES

  IMPLICIT NONE
  
  !Argument variables
  TYPE(PETSC_SNES_TYPE), INTENT(INOUT) :: SNES !<The PETSc SNES type
  INTEGER(INTG), INTENT(INOUT) :: ITS !<The iteration number
  REAL(DP), INTENT(INOUT) :: NORM !<The residual norm
  TYPE(SOLVER_TYPE), POINTER :: CTX !<The passed through context
  INTEGER(INTG), INTENT(INOUT) :: ERR !<The error code
  !Local Variables
  TYPE(NONLINEAR_SOLVER_TYPE), POINTER :: NONLINEAR_SOLVER
  TYPE(VARYING_STRING) :: ERROR,LOCAL_ERROR

  IF(ASSOCIATED(CTX)) THEN
    IF(CTX%SOLVE_TYPE==SOLVER_NONLINEAR_TYPE) THEN
      NONLINEAR_SOLVER=>CTX%NONLINEAR_SOLVER

      CALL SOLVER_NONLINEAR_MONITOR(NONLINEAR_SOLVER,ITS,NORM,ERR,ERROR,*999)

    ELSE
      LOCAL_ERROR="Invalid solve type. The solve type of "//TRIM(NUMBER_TO_VSTRING(CTX%SOLVE_TYPE,"*",ERR,ERROR))// &
        & " does not correspond to a nonlinear solver."
      CALL FLAG_ERROR(LOCAL_ERROR,ERR,ERROR,*999)
    ENDIF      
  ELSE
    CALL FLAG_ERROR("Solver context is not associated.",ERR,ERROR,*999)
  ENDIF
  
  RETURN
999 CALL WRITE_ERROR(ERR,ERROR,*998)
998 CALL FLAG_WARNING("Error monitoring nonlinear solve.",ERR,ERROR,*997)
997 RETURN    
END SUBROUTINE SOLVER_NONLINEAR_MONITOR_PETSC

