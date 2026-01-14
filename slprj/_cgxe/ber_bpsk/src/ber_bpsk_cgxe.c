/* Include files */

#include "ber_bpsk_cgxe.h"
#include "m_IGPkuFeb7GxDBK93y9JMnB.h"

unsigned int cgxe_ber_bpsk_method_dispatcher(SimStruct* S, int_T method, void
  * data)
{
  if (ssGetChecksum0(S) == 3945484508 &&
      ssGetChecksum1(S) == 752270978 &&
      ssGetChecksum2(S) == 608457128 &&
      ssGetChecksum3(S) == 2749872506) {
    method_dispatcher_IGPkuFeb7GxDBK93y9JMnB(S, method, data);
    return 1;
  }

  return 0;
}
