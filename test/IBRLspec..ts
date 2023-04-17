import { loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'

describe('IBRL', function () {
  async function deployContract() {
    const [owner, user1, user2] = await ethers.getSigners()

    const initialSupply = '100000'

    const IBRL = await ethers.getContractFactory('IBRL')
    const ibrl = await IBRL.deploy(initialSupply)

    return { ibrl, owner, user1, user2, initialSupply }
  }

  describe('Deployment', function () {
    it('Should set the totalSupply equivalent to 100_000 ether', async function () {
      const { ibrl, initialSupply } = await loadFixture(deployContract)

      const totalSupply = (await ibrl.functions.totalSupply()).toString()

      expect(totalSupply).to.be.equal(ethers.utils.parseEther(initialSupply))
    })

    it('Should set the smart contract as the totalSupply holder', async function () {
      const { ibrl } = await loadFixture(deployContract)

      const smartContractBalance = await ibrl.functions.balanceOf(ibrl.address)
      const totalSupply = await ibrl.functions.totalSupply()

      expect(smartContractBalance.toString()).to.be.equal(
        totalSupply.toString()
      )
    })

    it('Should set the right owner', async function () {
      const { ibrl, owner } = await loadFixture(deployContract)

      expect(await ibrl.owner()).to.equal(owner.address)
    })

    it('Should fail if the initialSupply argument is zero', async function () {
      const IBRL = await ethers.getContractFactory('IBRL')

      await expect(IBRL.deploy('0')).to.be.revertedWith(
        '[IBRL#constructor]: Invalid initialSupply.'
      )
    })
  })

  describe('Methods', function () {
    describe('Validations', function () {
      it.skip('Should revert if mint is called from a non-onwer account', async function () {
        const { ibrl, user1 } = await loadFixture(deployContract)

        const user1AsSigner = ibrl.connect(user1)
        const amountToBeMinted = ethers.utils.parseEther('100')

        await expect(
          user1AsSigner.functions.mint(user1.address, amountToBeMinted)
        ).to.be.revertedWith('[IBRL]: Caller is not the owner.')
      })

      it.skip('Should revert if burn is called from a non-onwer account', async function () {
        const { ibrl, user1, user2 } = await loadFixture(deployContract)

        const user1AsSigner = ibrl.connect(user1)
        const amountToBeBurned = ethers.utils.parseEther('100')

        await expect(
          user1AsSigner.functions.burn(user2.address, amountToBeBurned)
        ).to.be.revertedWith('[IBRL]: Caller is not the owner.')
      })

      it('Should revert if sender doesnt have enough funds to transfer', async function () {
        const { ibrl, user1, user2 } = await loadFixture(deployContract)

        const user1AsSigner = ibrl.connect(user1)
        const amountToBeTransferred = ethers.utils.parseEther('100')

        await expect(
          user1AsSigner.functions.transfer(user2.address, amountToBeTransferred)
        ).to.be.revertedWith('[IBRL#transfer]: Insufficient balance.')
      })
    })

    describe('Transfers', function () {
      it('Should mint 1 gwei to user1', async function () {
        const { ibrl, user1 } = await loadFixture(deployContract)

        const transferAmount = ethers.utils.parseUnits('1', 'gwei')

        await expect(
          ibrl.functions.mint(user1.address, transferAmount)
        ).to.changeTokenBalances(
          ibrl,
          [ibrl.address, user1.address],
          [-transferAmount, transferAmount]
        )
      })

      it('Should successfuly transfer when sender has enough funds', async function () {
        const { ibrl, user1, user2 } = await loadFixture(deployContract)

        const mintAmount = ethers.utils.parseUnits('1', 'ether')
        await ibrl.functions.mint(user1.address, mintAmount)

        const user1AsSigner = ibrl.connect(user1)
        const transferAmount = ethers.utils.parseUnits('1', 'gwei')

        await expect(
          user1AsSigner.functions.transfer(user2.address, transferAmount)
        ).to.changeTokenBalances(
          ibrl,
          [user1.address, user2.address],
          [-transferAmount, transferAmount]
        )
      })
    })
  })
})
