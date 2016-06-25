/* xilinx_pci_fpc_main.c: A driver for PCIe-based FPC of Xilinx FPGAs */

/*
  A Linux device driver for PCIe-based Fast Partial Configuration (FPC)
  of Xilinx Field Programmable Gate Array (FPGA) devices.

  Authors and other copyright holders:
  2012 by Eldridge M. Mount IV
  Copyright 2012 Xilinx

  This software may be used and distributed according to the terms of
  the GNU General Public License (GPL), incorporated herein by reference.
  Drivers based on or derived from this code fall under the GPL and must
  retain the authorship, copyright and license notice.  This file is not
  a complete program and may only be used when the entire operating
  system is licensed under the GPL.

*/

#define DRV_NAME     "xilinx-pci-fpc"
#define DRV_VERSION  "1.00"
#define DRV_RELDATE  "3/8/2012"


/* The user-configurable values.
   These may be modified when a driver module is loaded.*/

static int debug = 1;      /* 1 normal messages, 0 quiet .. 7 verbose. */

// For sleep
#include <linux/delay.h>

#include <linux/cdev.h>
#include <linux/errno.h>
#include <linux/fs.h>
#include <linux/init.h>
#include <linux/interrupt.h>
#include <linux/kernel.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/pci.h>
#include <linux/types.h>
#include "xilinx_pci_fpc.h"
#include "../common/xilinx_fpc_constants.h"

#include <asm/io.h>
#include <asm/irq.h>
#include <linux/version.h>
#if LINUX_VERSION_CODE > KERNEL_VERSION(3, 3, 0)
    #include <asm/switch_to.h>
#else
    #include <asm/system.h>
#endif
#include <asm/uaccess.h>

/* These identify the driver base version and may not be removed. */
#if LINUX_VERSION_CODE > KERNEL_VERSION(3, 3, 0)
static const char version[] __initconst =
  KERN_INFO DRV_NAME ".c:v" DRV_VERSION " " DRV_RELDATE
  " Eldridge Mount (emount@rochester.rr.com)\n";
#else
static const char version[] __devinitconst =
  KERN_INFO DRV_NAME ".c:v" DRV_VERSION " " DRV_RELDATE
  " Eldridge Mount (emount@rochester.rr.com)\n";
#endif

#if defined(__powerpc__)
#define inl_le(addr)  le32_to_cpu(inl(addr))
#define inw_le(addr)  le16_to_cpu(inw(addr))
#endif

#define PFX DRV_NAME ": "

MODULE_AUTHOR("Eldridge M. Mount IV");
MODULE_DESCRIPTION("PCI-based Fast Partial Configuration (FPC) driver for Xilinx FPGAs");
MODULE_LICENSE("GPL");

module_param(debug, int, 0);
MODULE_PARM_DESC(debug, "debug level (1-2)");

/* Register offset definitions */
#define FPC_IO_FIRST  (0x00)
#define FPC_IO_EXTENT (0x20)

/* Use 32 bit data-movement operations instead of 16 bit. */
#define USE_LONGIO

/* Structure storing option flags specific to each supported board */
/* TODO - Update these to actually contain supported board names and
 *        some meaningful flags, if any

static struct {
  char *name;
  int flags;
} pci_clone_list[] __devinitdata = {
  {"Xilinx_DemoBoard", 0},
  {NULL, }
};

 */

/* Macros for writing and reading memory-mapped I/O registers over PCIe */
#define RTL_W8(reg, val8)    writeb ((val8),  (fpc_dev->iobase_virt + (reg)))
#define RTL_W16(reg, val16)  writew ((val16), (fpc_dev->iobase_virt + (reg)))
#define RTL_W32(reg, val32)  writel ((val32), (fpc_dev->iobase_virt + (reg)))
#define RTL_R8(reg)          readb (fpc_dev->iobase_virt + (reg))
#define RTL_R16(reg)         readw (fpc_dev->iobase_virt + (reg))
#define RTL_R32(reg)         ((unsigned long) readl (fpc_dev->iobase_virt + (reg)))

/* Register offsets */
#define ICAP_BASE  (0x00)

/* Enumeration providing a natural ordering to the different cards we support
 * with this driver.  This is subsequently used to access card-specific driver
 * information during probing
 */
enum fpc_pci_cards {
  CARD_XILINX_REFERENCE = 0,
};

/* Device table to register the driver for */
static DEFINE_PCI_DEVICE_TABLE(fpc_pci_tbl) = {
  { XILINX_VENDOR_ID, FPC_DEVICE_ID, PCI_ANY_ID, PCI_ANY_ID, 0, 0, CARD_XILINX_REFERENCE},
  { 0, }
};
MODULE_DEVICE_TABLE(pci, fpc_pci_tbl);

#define NAME_MAX_SIZE  80

/* Enumerated type representing configuration state */
typedef enum {
  CONFIG_INIT     = 0,
  CONFIG_LOADING,
  CONFIG_COMPLETE,
  CONFIG_ERROR
} ConfigState;

/* Structure definition for encapsulating information about each device */
struct pci_fpc_device {

  /* Parent PCI device */
  struct pci_dev *pci_parent;

  /* Misc device structure */
  struct miscdevice miscdev;

  /* Name of the device */
  char name[NAME_MAX_SIZE];

  /* Device I/O addresses (physical as well as virtual) */
  unsigned long  iobase_phys;
  void __iomem *iobase_virt;

  /* IRQ assignment */
  unsigned int irq;

  /* Configuration state space */
  ConfigState           config_state;
  uint32_t              block_count;
  uint32_t              words_left;
  struct fpc_data_block data_block;
};

/* Array of existing devices */
#define MAX_FPC_DEVICES 16

static struct pci_fpc_device* devices[MAX_FPC_DEVICES] = {};

static int xilinx_fpc_open_cdev(struct inode *inode, struct file *filp) {
  uint32_t dev_index;
  struct pci_fpc_device *dma_pdev = NULL;
  int ret_value = 0;

  for(dev_index = 0; dev_index < MAX_FPC_DEVICES; dev_index++) {
    if((devices[dev_index] != NULL) && (devices[dev_index]->miscdev.minor == iminor(inode))) {
      dma_pdev = devices[dev_index];
      filp->private_data = dma_pdev;
      break;
    }
  }

  if(dma_pdev == NULL) {
    printk("%s: Unable to locate driver instance\n", DRV_NAME);
    ret_value = -ENODEV;
  }

  return(ret_value);
}

static int xilinx_fpc_release_cdev(struct inode *inode, struct file *filp) {
  struct pci_fpc_device *dma_pdev;

  /* The device is being closed */
  dma_pdev = (struct pci_fpc_device*) filp->private_data;

  return(0);
}

static long xilinx_fpc_ioctl_cdev(struct file *filp,
          unsigned int command,
          unsigned long arg) {
  struct pci_fpc_device *fpc_dev = (struct pci_fpc_device*) filp->private_data;

  /* Switch upon the command being requested */
  switch(command) {
  case IOC_GET_BOARD_ID:
    {
      struct fpc_board_id board_id;

      /* Return the vendor and device from the PCI device structure */
      board_id.vendor = fpc_dev->pci_parent->vendor;
      board_id.device = fpc_dev->pci_parent->device;
      if(copy_to_user((void __user*) arg, &board_id, sizeof(struct fpc_board_id)) != 0) {
        return(-EFAULT);
      }
    }
    break;

  case IOC_INIT_CONFIG:
    {
      /* Initialize the configuration state space */
      fpc_dev->config_state = CONFIG_INIT;
      fpc_dev->block_count    = 0;
      fpc_dev->words_left = (uint32_t) arg;

      /* Place the board into partial configuration mode.
       *
       * TODO : As the design stands, only a single configuration may be
       *        performed per power cycle, so this is enforced.  In the future,
       *        it should be possible to perform an arbitrary number of config
       *        cycles.
       */
      printk("Initialized partial configuration, will accept %d blocks\n",
       fpc_dev->words_left);
    }
    break;

  case IOC_CONFIG_BLOCK:
    {
      uint32_t word_index;
      uint32_t block_size;

      if(copy_from_user(&fpc_dev->data_block,
                        (void __user*) arg,
                        sizeof(struct fpc_data_block)) != 0) return(-EFAULT);

      /* Load the data block into the configuration logic via PCIe.  The entire
       * BAR is mapped to the configuration loading logic.  Load the lesser of the
       * stated block size or the remaining words from the initialization call.
       */
      block_size = ((fpc_dev->data_block.num_words < fpc_dev->words_left) ?
                    fpc_dev->data_block.num_words : fpc_dev->words_left);
      for(word_index = 0; word_index < block_size; word_index++) {
        /* Write 32-bit values of configuration data, converting to little-endian
	 * from the native endian-ness as necessary
	 */
        RTL_W32(ICAP_BASE, cpu_to_le32(fpc_dev->data_block.block_words[word_index]));
//        msleep(1);
      }

      /* Decrement the words remaining, testing for completion */
      fpc_dev->words_left -= block_size;
      if(fpc_dev->words_left == 0) {
	printk("Reached final FPC block count\n");
      }
    }
    break;

  default:
    /* Invalid command */
    return(-EINVAL);
  }

  return(0);
}


/***************************************************************************
 * Name:        mmap_kmem
 *
 * Description: Helper function to create a page table entry which maps userspace
 *              virtual memory address directly to the physical memory of the device. 
 *              So, we can directly perform write/read operation using virtual address
 *              in the userspace.
 *
 * Arguments:  
 *            filp  : File pointer to opened device.
 *            vma   :  
 *
 * Returns: the starting virtual address; error code on failure.
 *
 * Modification log:
 * Date      Who  Description
 * --------  ---  ----------------------------------------------------------
 *
 ****************************************************************************/


int mmap_kmem(struct file * filp, struct vm_area_struct * vma)
{
  int ret = 0;
  printk(KERN_INFO "Mapping physical to usr virtual address \n"); 
  struct pci_fpc_device *fpc_dev = (struct pci_fpc_device*) filp->private_data; 
  ret = remap_pfn_range(vma, vma->vm_start, (fpc_dev->iobase_phys) >> PAGE_SHIFT, vma->vm_end - vma->vm_start, vma->vm_page_prot);
  return ret; 
}

/***************************************************************************
 * Name:       XPCIe_Mmap 
 *
 * Description: function in kernel space for virtual-physical address mapping.
 *
 * Arguments:  
 *            filp  : File pointer to opened device.
 *            vma   :  
 *
 * Returns: the starting virtual address; error code on failure.
 *
 * Modification log:
 * Date      Who  Description
 * --------  ---  ----------------------------------------------------------
 *
 ****************************************************************************/

static int xilinx_mmap (struct file *filp, struct vm_area_struct *vma)
{
  printk(KERN_INFO"mmap is invoked\n");
  return mmap_kmem(filp, vma);
}




/* Character device file operations structure for the driver */
static const struct file_operations xilinx_fpc_fops = {
  .open           = xilinx_fpc_open_cdev,
  .release        = xilinx_fpc_release_cdev,
  .unlocked_ioctl = xilinx_fpc_ioctl_cdev,
  .mmap           = xilinx_mmap,
};

/* Interrupt service routine */
static irqreturn_t xilinx_pci_fpc_isr(int irq, void *dev_id) {
  //  struct pci_fpc_device *fpc_dev = (struct fpc_device*) dev_id;

  return(IRQ_HANDLED);
}

/* Probe function */
#if LINUX_VERSION_CODE > KERNEL_VERSION(3, 3, 0)
static int __init fpc_pci_init_one(struct pci_dev *pdev, const struct pci_device_id *ent) {
#ifndef MODULE
  static int printed_version  = 0;
#endif
  static unsigned int fnd_cnt = 0;
  struct pci_fpc_device *fpc_dev;
  int ret_value = 0;
  uint32_t dev_index;
#else
static int __devinit fpc_pci_init_one(struct pci_dev *pdev, const struct pci_device_id *ent) {
#ifndef MODULE
  static int printed_version  = 0;
#endif
  static unsigned int fnd_cnt = 0;
  struct pci_fpc_device *fpc_dev;
  int ret_value = 0;
  uint32_t dev_index;
#endif

  /* When built into the kernel, we only print version if device is found */
#ifndef MODULE
  if(!printed_version++)
    printk(version);
#endif

  /* Allocate a private device structure to store state information about the
   * device.  This will be attached to the PCI device structure.
   */
  fpc_dev = devm_kzalloc(&pdev->dev, sizeof(struct pci_fpc_device), GFP_KERNEL);
  if(fpc_dev == NULL) {
    return(-ENOMEM);
  }
  snprintf(fpc_dev->name, NAME_MAX_SIZE, "pci_fpc%d", fnd_cnt++);
  fpc_dev->name[NAME_MAX_SIZE - 1] = '\0';

  /* Disable message-signaled interrupts and then enable the device */
  pci_msi_off(pdev);
  ret_value = pci_enable_device(pdev);
  if(ret_value) {
    dev_err(&pdev->dev, "failed to enable device\n");
    goto err_kfree;
  }

  /* Request the PCI regions for the device */
  ret_value = pci_request_regions(pdev, DRV_NAME);
  if(ret_value < 0) {
    dev_err(&pdev->dev, "PCI regions request failed\n");
    goto err_disable;
  }

  /* Get the address mapped to BAR #(FPC_BAR_NUM) */
  fpc_dev->iobase_phys = pci_resource_start(pdev, FPC_BAR_NUM);
  fpc_dev->irq = pdev->irq;
  if (!fpc_dev->iobase_phys || ((pci_resource_flags(pdev, FPC_BAR_NUM) & IORESOURCE_MEM) == 0)) {
    dev_err(&pdev->dev, "No memory resource at PCI BAR #%d\n", FPC_BAR_NUM);
    ret_value = -ENODEV;
    goto err_release;
  }

  /* Map the address region into virtual memory as write-combined */
  fpc_dev->iobase_virt = ioremap_wc(fpc_dev->iobase_phys, pci_resource_len(pdev, FPC_BAR_NUM));
  if(!fpc_dev->iobase_virt) {
    dev_err(&pdev->dev, "Unable to map PCI BAR #%d to virtual memory\n", FPC_BAR_NUM);
    ret_value = -ENOMEM;
    goto err_release;
  }

  /* Register the device with the kernel as a miscellaneous device and hang on to
   * a local pointer to the parent PCI device
   */
  fpc_dev->pci_parent     = pdev;
  fpc_dev->miscdev.parent = &pdev->dev;
  fpc_dev->miscdev.minor  = MISC_DYNAMIC_MINOR;
  fpc_dev->miscdev.name   = fpc_dev->name;
  fpc_dev->miscdev.fops   = &xilinx_fpc_fops;
  ret_value = misc_register(&fpc_dev->miscdev);
  if(ret_value != 0) {
    dev_err(&pdev->dev, "%s: Unable to register misc device\n", fpc_dev->name);
    goto err_unmap;
  }

  /* Request the device's IRQ */
//  if(request_irq(fpc_dev->irq, xilinx_pci_fpc_isr, IRQF_SHARED, DRV_NAME, fpc_dev) != 0) {
//    dev_err(&pdev->dev, "%s: Unable to claim IRQ %d\n", fpc_dev->name, fpc_dev->irq);
//    goto err_deregister;
//  }

  /* Initialize the configuration state space */
  fpc_dev->config_state = CONFIG_INIT;
  fpc_dev->block_count    = 0;

  /* Set the private driver data for the card */
  pci_set_drvdata(pdev, fpc_dev);

  /* Store the device in a static array to be found during character device
   * initialization
   */
  for(dev_index = 0; dev_index < MAX_FPC_DEVICES; dev_index++) {
    if(devices[dev_index] == NULL) {
      devices[dev_index] = fpc_dev;
      break;
    }
  }

  printk("%s: Device found at 0x%08X, IRQ %d\nBAR%d mapped from 0x%08X - 0x%08X\n",
     fpc_dev->name,
   (unsigned int) fpc_dev->iobase_phys,
   fpc_dev->irq,
   FPC_BAR_NUM,
   (unsigned int) fpc_dev->iobase_virt,
   (unsigned int) (fpc_dev->iobase_virt + pci_resource_len(pdev, FPC_BAR_NUM) - 1));

  return(0);

  /* Error-unwinding jump targets */
 err_deregister:
  misc_deregister(&fpc_dev->miscdev);
 err_unmap:
  iounmap(fpc_dev->iobase_virt);
  fpc_dev->iobase_virt = NULL;
 err_release:
  pci_release_regions(pdev);
 err_disable:
  pci_disable_device(pdev);
  pci_set_drvdata(pdev, NULL);
 err_kfree:
  kfree(fpc_dev);

  return(ret_value);
}

#ifdef NOTYET

/* Replace these with platform character / MISC device open / close calls */
static int fpc_pci_open(struct net_device *dev)
{
  int ret = request_irq(dev->irq, ei_interrupt, IRQF_SHARED, dev->name, dev);
  if (ret)
    return ret;

  if (ei_status.fpc_flags & FORCE_FDX)
    fpc_pci_set_fdx(dev);

  ei_open(dev);
  return 0;
}

static int fpc_pci_close(struct net_device *dev)
{
  ei_close(dev);
  free_irq(dev->irq, dev);
  return 0;
}

#endif // NOTYET

/* Release function */
#if LINUX_VERSION_CODE > KERNEL_VERSION(3, 3, 0)
static void __exit fpc_pci_remove_one (struct pci_dev *pdev)
{
  struct pci_fpc_device *fpc_dev = pci_get_drvdata(pdev);
  uint32_t dev_index;

  BUG_ON(!fpc_dev);

  /* Release the IRQ */
  if(fpc_dev->irq >= 0) free_irq(fpc_dev->irq, fpc_dev);

  /* Deregister the misc device and remove it from the list of devices */
  misc_deregister(&fpc_dev->miscdev);
  for(dev_index = 0; dev_index < MAX_FPC_DEVICES; dev_index++) {
    if(fpc_dev == devices[dev_index]) {
      devices[dev_index] = NULL;
      break;
    }
  }

  /* Release all resources claimed and / or allocated during the probe */
  if(fpc_dev->iobase_virt) {
    iounmap(fpc_dev->iobase_virt);
    fpc_dev->iobase_virt = NULL;
  }
  pci_release_regions(pdev);
  pci_disable_device(pdev);
  pci_set_drvdata(pdev, NULL);
  kfree(fpc_dev);
}
#else
static void __devexit fpc_pci_remove_one (struct pci_dev *pdev)
{
  struct pci_fpc_device *fpc_dev = pci_get_drvdata(pdev);
  uint32_t dev_index;

  BUG_ON(!fpc_dev);

  /* Release the IRQ */
  if(fpc_dev->irq >= 0) free_irq(fpc_dev->irq, fpc_dev);

  /* Deregister the misc device and remove it from the list of devices */
  misc_deregister(&fpc_dev->miscdev);
  for(dev_index = 0; dev_index < MAX_FPC_DEVICES; dev_index++) {
    if(fpc_dev == devices[dev_index]) {
      devices[dev_index] = NULL;
      break;
    }
  }

  /* Release all resources claimed and / or allocated during the probe */
  if(fpc_dev->iobase_virt) {
    iounmap(fpc_dev->iobase_virt);
    fpc_dev->iobase_virt = NULL;
  }
  pci_release_regions(pdev);
  pci_disable_device(pdev);
  pci_set_drvdata(pdev, NULL);
  kfree(fpc_dev);
}
#endif

/* Functions for use with power management events */
#ifdef CONFIG_PM

static int fpc_pci_suspend (struct pci_dev *pdev, pm_message_t state)
{
  /*  struct pci_fpc_device *fpc_dev = pci_get_drvdata (pdev); */

  pci_save_state(pdev);
  pci_disable_device(pdev);
  pci_set_power_state(pdev, pci_choose_state(pdev, state));

  return 0;
}

static int fpc_pci_resume (struct pci_dev *pdev)
{
  /*  struct pci_fpc_device *fpc_dev = pci_get_drvdata (pdev); */
  int rc;

  pci_set_power_state(pdev, 0);
  pci_restore_state(pdev);

  rc = pci_enable_device(pdev);
  if (rc)
    return rc;

  return 0;
}

#endif /* CONFIG_PM */

#if LINUX_VERSION_CODE > KERNEL_VERSION(3, 3, 0)
static struct pci_driver xilinx_fpc_driver = {
  .name     = DRV_NAME,
  .probe    = fpc_pci_init_one,
  .remove   = __exit_p(fpc_pci_remove_one),
  .id_table = fpc_pci_tbl,
#ifdef CONFIG_PM
  .suspend  = fpc_pci_suspend,
  .resume   = fpc_pci_resume,
#endif /* CONFIG_PM */
};
#else
static struct pci_driver xilinx_fpc_driver = {
  .name     = DRV_NAME,
  .probe    = fpc_pci_init_one,
  .remove   = __devexit_p(fpc_pci_remove_one),
  .id_table = fpc_pci_tbl,
#ifdef CONFIG_PM
  .suspend  = fpc_pci_suspend,
  .resume   = fpc_pci_resume,
#endif /* CONFIG_PM */
};
#endif

static int __init fpc_pci_init(void)
{
  uint32_t dev_index;

  /* when a module, this is printed whether or not devices are found in probe */
#ifdef MODULE
  printk(version);
#endif

  /* Clear the static array of device pointers */
  for(dev_index = 0; dev_index < MAX_FPC_DEVICES; dev_index++) {
    devices[dev_index] = NULL;
  }

  return pci_register_driver(&xilinx_fpc_driver);
}

static void __exit fpc_pci_cleanup(void)
{
  pci_unregister_driver(&xilinx_fpc_driver);
}

module_init(fpc_pci_init);
module_exit(fpc_pci_cleanup);
