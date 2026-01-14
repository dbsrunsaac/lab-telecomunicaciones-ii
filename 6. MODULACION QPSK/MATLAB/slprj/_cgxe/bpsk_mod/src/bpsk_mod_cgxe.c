/* Include files */

#include "bpsk_mod_cgxe.h"
#include "m_Z4uLkjHxQb3PwwWdk2gHaF.h"

unsigned int cgxe_bpsk_mod_method_dispatcher(SimStruct* S, int_T method, void
  * data)
{
  if (ssGetChecksum0(S) == 1519489918 &&
      ssGetChecksum1(S) == 1056786459 &&
      ssGetChecksum2(S) == 3725301226 &&
      ssGetChecksum3(S) == 3969503232) {
    method_dispatcher_Z4uLkjHxQb3PwwWdk2gHaF(S, method, data);
    return 1;
  }

  return 0;
}
